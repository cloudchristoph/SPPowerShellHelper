<#
.SYNOPSIS
    Adds a new index component.
.DESCRIPTION
    Adds a new index component.
    Needs to run on the specific server because the search service instance is used local.
    Deletes old topologies.
.NOTES
    File Name  : Add-SPIndexComponent.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Add-SPIndexComponent.ps1 -IndexRootDirectory "D:\SP-Search\INDEX" -SearchServiceName "SSA"
    Add-SPIndexComponent.ps1 -IndexRootDirectory "D:\SP-Search\INDEX" -SearchServiceName "SSA" -IndexPartition 1
.PARAMETER IndexRootDirectory
    The root directory of the index.
.PARAMETER IndexPartition
    The number of the index partition.
    Default is 0.
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
    [ValidateNotNullOrEmpty()]
    [string]
    $IndexRootDirectory,
    
    [Parameter(Mandatory=$false)]
    [int]
    $IndexPartition = 0,

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
$ssi = Get-SPEnterpriseSearchServiceInstance -Local
Start-SPEnterpriseSearchServiceInstance -Identity $ssi

# Wait for Search Service Instance to come online
do {
    $online = Get-SPEnterpriseSearchServiceInstance -Identity $ssi
    Write-Verbose ("Waiting for service: " + $online.Status)
} 
until ($online.Status -eq "Online")

# Clone Active Search Topology
$active = Get-SPEnterpriseSearchTopology -SearchApplication $ssa -Active
$clone = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone –SearchTopology $active
# Create new components
$newIndexComponent = New-SPEnterpriseSearchIndexComponent –SearchTopology $clone -SearchApplication $ssa -SearchServiceInstance $ssi `
                                                          -IndexPartition $IndexPartition -RootDirectory $IndexRootDirectory
# Activate the Cloned Search Topology
Set-SPEnterpriseSearchTopology -Identity $clone

# Monitor Distribution of Index
do {
    $activeState1 = Get-SPEnterpriseSearchStatus -SearchApplication $ssa | Where-Object {$_.Name -eq $newIndexComponent.Name}
    
    $activeState = $activeState1.State -eq "Active"
    Write-Verbose ("Waiting for active distribution")
}
until ($activeState -eq $true)

# Delete old topology
Write-Verbose "Deleting old topology"
Get-SPEnterpriseSearchTopology -SearchApplication $ssa | ? { $_.State -eq "Inactive" } | Remove-SPEnterpriseSearchTopology -SearchApplication $ssa -Confirm:$false
Write-Verbose "Old topologies removed"

Write-Host "Please run 'Remove-SPSearchComponent' to remove old index components if necessary." -ForegroundColor Cyan