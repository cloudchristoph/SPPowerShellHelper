<#
.SYNOPSIS
    Creates a new service application of type: Search Service.
.DESCRIPTION
    Creates a new service application of type: Search Service.
    Creates a new service application proxy.
    Creates a new application pool if there is no existing one.
    Sets the content access account.
    Creates a new search topology.
    Removes inactive search topologies.
.NOTES
    File Name  : Create-SPSearchServiceApp.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Create-SPSearchServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_Search" -ContentAccessAccount $(Get-Credential)
    Create-SPSearchServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_Search" -ContentAccessAccount $(Get-Credential) -ServiceAppName "Search Service"
    Create-SPSearchServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_Search" -ContentAccessAccount $(Get-Credential) -ServiceAppName "Search Service" -AppPoolName "Existing AppPool Shared"
    Create-SPSearchServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_Search" -ContentAccessAccount $(Get-Credential) -ServiceAppName "Search Service" -AppPoolName "New AppPool App" -ManagedAccount "DEV\SP_Services"
    Create-SPSearchServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_Search" -ContentAccessAccount $(Get-Credential) -ServiceAppName "Search Service" -AppPoolName "New AppPool App" -ManagedAccount "DEV\SP_Services"
.PARAMETER ManagedAccount
    The managed account to be used for a new application pool. If you want to create a new application pool you have to specify a managed account.
    Needs to be in the following format: DOMAIN\USER
.PARAMETER AppPoolName
    The name of the existing or new application pool. If you want to create a new application pool you have to specify a managed account.
    Default is "AppPool_Search".
.PARAMETER ServiceAppName
    The name of the new service application.
    Default is "Search Service Application".
.PARAMETER DatabaseServer
    The name of the database server. Normally the SQL Alias.
.PARAMETER DatabaseName
    The name of the new database.
.PARAMETER ContentAccessAccount
    The content access account.
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
    $AppPoolName = "AppPool_Search",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ServiceAppName = "Search Service Application",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DatabaseServer,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DatabaseName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [pscredential]
    $ContentAccessAccount
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

$searchServiceApp = Get-SPServiceApplication | where {$_.TypeName -like "Search Service Application"} -ErrorAction SilentlyContinue
if ($null -ne $searchServiceApp) {
    Write-Error "Service Application of type Search Service Application already exists!"
    exit
}

$searchServiceApp = Get-SPServiceApplication -Name $ServiceAppName -ErrorAction SilentlyContinue
if ($null -ne $searchServiceApp) {
    Write-Error "Service Application with name $ServiceAppName already exists!"
    exit
}

# Start service instance

Write-Verbose "Starting service instance"

Get-SPEnterpriseSearchServiceInstance -Local | Start-SPEnterpriseSearchServiceInstance 
Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Local | Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance

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
$searchServiceApp = New-SPEnterpriseSearchServiceApplication -ApplicationPool $appPool -Name $ServiceAppName -DatabaseName $DatabaseName -DatabaseServer $DatabaseServer
Write-Verbose "Service Application created"

Write-Verbose "Creating Service Application Proxy"
$searchProxyServiceApp = New-SPEnterpriseSearchServiceApplicationProxy -SearchApplication $searchServiceApp -Name $($ServiceAppName + " Proxy")
Write-Verbose "Service Application Proxy created"

# Set content access account

Write-Verbose "Setting content access account"
Set-SPEnterpriseSearchServiceApplication -Identity $searchServiceApp -DefaultContentAccessAccountName $ContentAccessAccount.UserName -DefaultContentAccessAccountPassword $ContentAccessAccount.Password
Write-Verbose "Content access account set"

#Clone topology

Write-Verbose "Creating new topology"
$active = Get-SPEnterpriseSearchTopology -SearchApplication $searchServiceApp -Active
$clone = New-SPEnterpriseSearchTopology -SearchApplication $searchServiceApp -Clone –SearchTopology $active

#Create new topology

$searchServiceInst = Get-SPEnterpriseSearchServiceInstance
$componentAdmin = New-SPEnterpriseSearchAdminComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInst
$componentContenProcessing = New-SPEnterpriseSearchContentProcessingComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInst
$componentAnalyticsProcessing = New-SPEnterpriseSearchAnalyticsProcessingComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInst
$componentCrawl = New-SPEnterpriseSearchCrawlComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInst 
$componentIndex = New-SPEnterpriseSearchIndexComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInst
$componentQueryProcessing = New-SPEnterpriseSearchQueryProcessingComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInst
Write-Verbose "New topology created"

#Activate new topology

Write-Verbose "Activating new topology"
Set-SPEnterpriseSearchTopology -Identity $clone
Write-Verbose "New topology activated"

# Delete old topology

Write-Verbose "Deleting old topology"
Get-SPEnterpriseSearchTopology -SearchApplication $ssa | ? { $_.State -eq "Inactive" } | Remove-SPEnterpriseSearchTopology -SearchApplication $ssa -Confirm:$false
Write-Verbose "Old topologies removed"

Write-Host "Search Service Application created"