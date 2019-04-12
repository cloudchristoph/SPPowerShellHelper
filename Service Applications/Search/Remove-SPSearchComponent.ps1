<#
.SYNOPSIS
    Removes a search component.
.DESCRIPTION
    Removes a search component.
    Needs to run on the specific server because the search service instance is used local.
    Deletes old topologies.
    Run under elevated priviledges.
.NOTES
    File Name  : Remove-SPSearchComponent.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Remove-SPSearchComponent.ps1 -SearchServiceName "SSA" -OldComponents @("IndexComponent1", "CrawlComponent2")
.PARAMETER OldComponents
    A list of components to delete.
    Please use names instead of GUIDs. There could be errors.
.PARAMETER SearchServiceName
    The name of the search service application.
#>

##############################
#
# Parameters
#
##############################

param(
    [Parameter(Mandatory=$true)]
    [string[]]
    $OldComponents,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SearchServiceName
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

$ssa = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceName
if($null -eq $ssa)
{
    Write-Error "No Search Service Application with name $SearchServiceName found"
    exit
}
$active = Get-SPEnterpriseSearchTopology -SearchApplication $ssa -Active

$components = Get-SPEnterpriseSearchComponent -SearchTopology $active
Write-Verbose "Checking topology for components."
$OldComponents | ForEach-Object -Process {
    $oldComponent = $_
    $result = $($components | select ComponentId, Name) | where { $_.ComponentId -eq $oldComponent -or $_.Name -eq $oldComponent }
    if($null -eq $result -or $result.Count -lt 1)
    {
        Write-Error "No component $oldComponent found."
        exit
    }
}

Write-Verbose "Cloning active topology"
$clone = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone –SearchTopology $active

Write-Verbose "Removing old components."
$OldComponents | ForEach-Object -Process {
    Remove-SPEnterpriseSearchComponent -Identity $_ -SearchApplication $ssa -SearchTopology $clone -Confirm:$false
    Write-Verbose "Removing component $_"
}

Write-Verbose "Setting new topology."
Set-SPEnterpriseSearchTopology -Identity $clone

# Delete old topology
Write-Verbose "Deleting old topologies."
Get-SPEnterpriseSearchTopology -SearchApplication $ssa | ? { $_.State -eq "Inactive" } | Remove-SPEnterpriseSearchTopology -SearchApplication $ssa -Confirm:$false
Write-Verbose "Old topologies removed"