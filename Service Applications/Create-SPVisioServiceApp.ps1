<#
.SYNOPSIS
    Creates a new service application of type: Visio Graphics Service.
.DESCRIPTION
    Creates a new service application of type: Visio Graphics Service.
    Creates a new service application proxy.
    Creates a new application pool if there is no existing one.
.NOTES
    File Name  : Create-SPVisioServiceApp.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Create-SPVisioServiceApp.ps1
    Create-SPVisioServiceApp.ps1 -ServiceAppName "Visio Service"
    Create-SPVisioServiceApp.ps1 -ServiceAppName "Visio Service" -AppPoolName "Existing AppPool Shared"
    Create-SPVisioServiceApp.ps1 -ServiceAppName "Visio Service" -AppPoolName "New AppPool App" -ManagedAccount "DEV\SP_Services"
.PARAMETER ManagedAccount
    The managed account to be used for a new application pool. If you want to create a new application pool you have to specify a managed account.
    Needs to be in the following format: DOMAIN\USER
.PARAMETER AppPoolName
    The name of the existing or new application pool. If you want to create a new application pool you have to specify a managed account.
    Default is "AppPool_Visio".
.PARAMETER ServiceAppName
    The name of the new service application.
    Default is "Visio Service Application".
#>

##############################
#
# Parameters
#
##############################

param(
    [Parameter(Mandatory = $false)]
    [string]
    $ManagedAccount,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AppPoolName = "AppPool_Visio",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ServiceAppName = "Visio Service Application"
)

##############################
#
# Snapins
#
##############################

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

##############################
#
# Main
#
##############################
 
# Error handling

$visioServiceApp = Get-SPServiceApplication | where {$_.TypeName -like "Visio Graphics Service Application"} -ErrorAction SilentlyContinue
if ($null -ne $visioServiceApp) {
    Write-Error "Service Application of type Visio Graphics Service Application already exists!"
    exit
}

$visioServiceApp = Get-SPServiceApplication -Name $ServiceAppName -ErrorAction SilentlyContinue
if ($null -ne $visioServiceApp) {
    Write-Error "Service Application with name $ServiceAppName already exists!"
    exit
}

# Start service instance

Write-Verbose "Starting service instance"
$si = Get-SPServiceInstance | where {$_.TypeName -like "Visio Graphics Service"}
$si | Start-SPServiceInstance

do {
    $si = Get-SPServiceInstance | where {$_.TypeName -like "Visio Graphics Service"}
    Write-Host "Waiting for provisioning. Current state: $($si.Status)"
    Start-Sleep -Seconds 5
}while ($si.Status -ne "Online")

Write-Verbose "Service instance started"

# Get or create app pool

Write-Verbose "Getting existing Application Pool"
$appPool = Get-SPServiceApplicationPool -Identity $AppPoolName -ErrorAction SilentlyContinue
if ($null -eq $appPool) {
    Write-Verbose "No Application Pool found. Creating a new one"
    if ([string]::IsNullOrEmpty($ManagedAccount)) {
        Write-Error "You need to specify a managed account to create a new Application Pool"
        exit
    }
    
    $account = Get-SPManagedAccount -Identity $ManagedAccount -ErrorAction SilentlyContinue
    if ($null -eq $account) {
        Write-Error "No managed account '$ManagedAccount' found"
        exit
    }

    Write-Verbose "Creating Application Pool"
    $appPool = New-SPServiceApplicationPool -Name $AppPoolName -Account $account
    Write-Verbose "Application Pool created"
}

# Create service app

Write-Verbose "Creating Service Application"
$visioServiceApp = New-SPVisioServiceApplication -ApplicationPool $appPool -Name $ServiceAppName
Write-Verbose "Service Application created"

Write-Verbose "Creating Service Application Proxy"
$visioProxyServiceApp = New-SPVisioServiceApplicationProxy -ServiceApplication $visioServiceApp -Name $($ServiceAppName + " Proxy")
Write-Verbose "Service Application Proxy created"

Write-Host "Visio Service Application created"