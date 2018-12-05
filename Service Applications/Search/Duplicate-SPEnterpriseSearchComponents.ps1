<#
.SYNOPSIS
    Duplicates all components to a specific server.
.DESCRIPTION
    Duplicates all components to a specific server.
    If you run the script on another server than on the target one the SharePoint-Cmdlet checks the index root directory on the current server. If it is not empty an error occurs.
.NOTES
    File Name  : Duplicate-SPEnterpriseSearchComponents.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Duplicate-SPEnterpriseSearchComponents.ps1 -IndexRootDirectory "D:\SP-Search\INDEX" -ServerToDuplicateComponents "TFNCSP7AP001" -SearchServiceName "SSA"
    Duplicate-SPEnterpriseSearchComponents.ps1 -IndexRootDirectory "D:\SP-Search\INDEX" -ServerToDuplicateComponents "TFNCSP7AP001" -SearchServiceName "SSA" -IndexPartition 1
.PARAMETER IndexRootDirectory
    The root directory of the index.
.PARAMETER IndexPartition
    The number of the index partition.
    Default is 0.
.PARAMETER ServerToDuplicateComponents
    Specifies the server where to duplicate the components.
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
    $ServerToDuplicateComponents,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SearchServiceName,

    [Parameter(Mandatory=$false)]
    [string]
    $IndexRootDirectory,
    
    [Parameter(Mandatory=$false)]
    [int]
    $IndexPartition = 0,
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

if($env:COMPUTERNAME -ne $ServerToDuplicateComponents)
{
    Write-Warning "Attention: The current server is another than the target one. This can cause problems with the index root directory. It'll be checked on the current server."
    Write-Warning "You have time to quit."
    Start-Sleep -Seconds 5
}

Write-Verbose "Getting Search Service Application"
$ssa = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceName
$ssi = Get-SPEnterpriseSearchServiceInstance -Identity $ServerToDuplicateComponents
Start-SPEnterpriseSearchServiceInstance -Identity $ssi

#Wait for Search Service Instance to come online
do {
    $online = Get-SPEnterpriseSearchServiceInstance -Identity $ssi
    Write-Verbose ("Waiting for service: " + $online.Status)
    Start-Sleep -Seconds 5
} 
until ($online.Status -eq "Online")

#Clone Active Search Topology
$active = Get-SPEnterpriseSearchTopology -SearchApplication $ssa -Active
$clone = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone –SearchTopology $active
#Create new components
if([string]::IsNullOrEmpty($IndexRootDirectory))
{
    $indexComponent = New-SPEnterpriseSearchIndexComponent –SearchTopology $clone -SearchApplication $ssa -SearchServiceInstance $ssi `
                                                           -IndexPartition $IndexPartition
}
else
{
    $indexComponent = New-SPEnterpriseSearchIndexComponent –SearchTopology $clone -SearchApplication $ssa -SearchServiceInstance $ssi `
                                                           -IndexPartition $IndexPartition -RootDirectory $IndexRootDirectory
}
$queryComponent = New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $clone -SearchServiceInstance $ssi -SearchApplication $ssa
$crawlComponent = New-SPEnterpriseSearchCrawlComponent -SearchTopology $clone -SearchServiceInstance $ssi -SearchApplication $ssa
$analyticsComponent = New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $clone -SearchServiceInstance $ssi -SearchApplication $ssa
$contentComponent = New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $clone -SearchServiceInstance $ssi -SearchApplication $ssa
$adminComponent = New-SPEnterpriseSearchAdminComponent -SearchTopology $clone -SearchServiceInstance $ssi -SearchApplication $ssa
#Activate the Cloned Search Topology
Set-SPEnterpriseSearchTopology -Identity $clone

#Monitor Distribution of Index
do {
    $activeState1 = Get-SPEnterpriseSearchStatus -SearchApplication $ssa | Where-Object {$_.Name -eq $indexComponent.Name}
    $activeState2 = Get-SPEnterpriseSearchStatus -SearchApplication $ssa | Where-Object {$_.Name -eq $queryComponent.Name}
    $activeState3 = Get-SPEnterpriseSearchStatus -SearchApplication $ssa | Where-Object {$_.Name -eq $crawlComponent.Name}
    $activeState4 = Get-SPEnterpriseSearchStatus -SearchApplication $ssa | Where-Object {$_.Name -eq $analyticsComponent.Name}
    $activeState5 = Get-SPEnterpriseSearchStatus -SearchApplication $ssa | Where-Object {$_.Name -eq $contentComponent.Name}
    $activeState6 = Get-SPEnterpriseSearchStatus -SearchApplication $ssa | Where-Object {$_.Name -eq $adminComponent.Name}
    
    $activeState = ($activeState1.State -eq "Active" -and `
                    $activeState2.State -eq "Active" -and `
                    $activeState3.State -eq "Active" -and `
                    $activeState4.State -eq "Active" -and `
                    $activeState5.State -eq "Active" -and `
                    $activeState6.State -eq "Active")
    Write-Verbose ("Waiting for active distribution")
    Start-Sleep -Seconds 5
}
until ($activeState -eq $true)

# Delete old topology
$inactiveSearchTopologies = Get-SPEnterpriseSearchTopology -SearchApplication $ssa | ? { $_.State -eq "Inactive" }
foreach ($topology in $inactiveSearchTopologies) {
    Remove-SPEnterpriseSearchTopology -SearchApplication $ssa -Identity $topology.TopologyId.Guid -Confirm:$false
}