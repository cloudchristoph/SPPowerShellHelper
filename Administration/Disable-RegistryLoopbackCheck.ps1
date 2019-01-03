<#
.SYNOPSIS
    Disables the LoopbackCheck of the current computer.
.DESCRIPTION
    Disables the LoopbackCheck of the current computer.
    Using either the BackConnectionHostNames or the DisableLoopbackCheck or both.
    Restarts IIS.
    Restarts Computer if necessary and confirmed.
.NOTES
    File Name  : Disable-RegistryLoopbackCheck.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Disable-RegistryLoopbackCheck.ps1 -BackConnectionHostNames ("pm.dev.local","intranet.dev.local")
    Disable-RegistryLoopbackCheck.ps1 -BackConnectionHostNames ("pm.dev.local","intranet.dev.local") -UpdateBackConnectionHostNames
    Disable-RegistryLoopbackCheck.ps1 -DisableLoopbackCheck
.PARAMETER BackConnectionHostNames
    Sets the BackConnectionHostNames.
    If already existing it overrides if UpdateBackConnectionHostNames is not specified.
    Do not use the protocols (http or https)
.PARAMETER DisableLoopbackCheck
    Sets the DisableLoopbackCheck.
.PARAMETER UpdateBackConnectionHostNames
    Updates the BackConnectionHostNames getting the current entries and adding the new ones.
#>

##############################
#
# Parameters
#
##############################

param(
    [Parameter(Mandatory = $false)]
    [string[]]
    $BackConnectionHostNames,

    [Parameter(Mandatory = $false)]
    [switch]
    $DisableLoopbackCheck,

    [Parameter(Mandatory = $false)]
    [switch]
    $UpdateBackConnectionHostNames
)

##############################
#
# Main
#
##############################

if ($null -eq $BackConnectionHostNames -and !$DisableLoopbackCheck) {
    Write-Error "Please set appropriate parameters"
    exit
}
elseif ($null -ne $BackConnectionHostNames -and !$DisableLoopbackCheck) {
    $BackConnectionHostNames | ForEach-Object {
        if ([string]::IsNullOrEmpty($_)) {
            Write-Error "There are empty entries in the back connection host names"
            exit
        }
    }
}

if ($null -ne $BackConnectionHostNames) {
    Write-Verbose "Searching for existing 'BackConnectionHostName' entry"
    $prop = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0 -Name "BackConnectionHostNames" -ErrorAction SilentlyContinue
    Write-Verbose "Setting 'BackConnectionHostName' in registry"
    if ($null -eq $prop) {
        Write-Verbose "No entry found. Creating new one."
        $prop = New-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0 -Name "BackConnectionHostNames" -value $BackConnectionHostNames -PropertyType multistring
    }
    else {
        Write-Verbose "Entry found."
        if ($UpdateBackConnectionHostNames) {
            Write-Verbose "Updating entry"
            $prop = Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0 -Name "BackConnectionHostNames" -Value @"
$BackConnectionHostNames
$($prop.BackConnectionHostNames)
"@
        }
        else {
            Write-Verbose "Setting entry - no update"
            $prop = Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0 -Name "BackConnectionHostNames" -value $BackConnectionHostNames
        }
    }
    $message = 'You need to restart the computer.'
    $question = 'Do you want to restart?'

    $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

    $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
    if ($decision -eq 0) {
        Write-Verbose "Restarting computer"
        Restart-Computer -Force
    }
    else {
        Write-Verbose "Restart still required"
    }
}

if ($DisableLoopbackCheck) {
    Write-Verbose "Searching for existing 'DisableLoopbackCheck' entry"
    $prop = Get-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopbackCheck" -ErrorAction SilentlyContinue
    Write-Verbose "Setting 'DisableLoopbackCheck' in registry to 1"
    if ($null -eq $prop) {
        Write-Verbose "No entry found. Creating new one."
        $prop = New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopbackCheck" -value "1" -PropertyType dword
    }
    else {
        Write-Verbose "Entry found."
        $prop = Set-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopbackCheck" -value "1"
    }
    Write-Verbose "Performing iis reset"
    iisreset /restart /noforce
}