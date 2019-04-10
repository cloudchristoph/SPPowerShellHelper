<#
.SYNOPSIS
    Creates a new service application of type: Business Data Connectivity Service.
.DESCRIPTION
    Creates a new service application of type: Business Data Connectivity Service.
    Creates a new service application proxy.
    Creates a new application pool if there is no existing one.
.NOTES
    File Name  : Create-SPBdcServiceApp.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Create-SPBdcServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_BdcService"
    Create-SPBdcServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_BdcService" -ServiceAppName "BDC Service"
    Create-SPBdcServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_BdcService" -ServiceAppName "BDC Service" -AppPoolName "Existing AppPool Shared"
    Create-SPBdcServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_BdcService" -ServiceAppName "BDC Service" -AppPoolName "New AppPool App" -ManagedAccount "DEV\SP_Services"
.PARAMETER ManagedAccount
    The managed account to be used for a new application pool. If you want to create a new application pool you have to specify a managed account.
    Needs to be in the following format: DOMAIN\USER
.PARAMETER AppPoolName
    The name of the existing or new application pool. If you want to create a new application pool you have to specify a managed account.
    Default is "AppPool_BDC".
.PARAMETER ServiceAppName
    The name of the new service application.
    Default is "Business Data Connectivity Service Application".
.PARAMETER DatabaseServer
    The name of the database server. Normally the SQL Alias.
.PARAMETER DatabaseName
    The name of the new database.
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
    $AppPoolName = "AppPool_BDC",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ServiceAppName = "Business Data Connectivity Service Application",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DatabaseServer,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DatabaseName
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

$bdcServiceApp = Get-SPServiceApplication | where {$_.TypeName -like "Business Data Connectivity Service Application"} -ErrorAction SilentlyContinue
if ($null -ne $bdcServiceApp) {
    Write-Error "Service Application of type Business Data Connectivity Service Application already exists!"
    exit
}

$bdcServiceApp = Get-SPServiceApplication -Name $ServiceAppName -ErrorAction SilentlyContinue
if ($null -ne $bdcServiceApp) {
    Write-Error "Service Application with name $ServiceAppName already exists!"
    exit
}

# Start service instance

Write-Verbose "Starting service instance"
$si = Get-SPServiceInstance | where {$_.TypeName -like "Business Data Connectivity Service"}
$si | Start-SPServiceInstance

do {
    $si = Get-SPServiceInstance | where {$_.TypeName -like "Business Data Connectivity Service"}
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
$bdcServiceApp = New-SPBusinessDataCatalogServiceApplication -ApplicationPool $appPool -Name $ServiceAppName -DatabaseName $DatabaseName -DatabaseServer $DatabaseServer
Write-Verbose "Service Application created"

Write-Verbose "Creating Service Application Proxy"
Write-Warning "The 'New-SPBusinessDataCatalogServiceApplication' should create a Proxy itself."
#$bdcProxyServiceApp = New-SPBusinessDataCatalogServiceApplicationProxy -ServiceApplication $bdcServiceApp -Name $($ServiceAppName + " Proxy")
#Write-Verbose "Service Application Proxy created"

Write-Host "Business Data Connectivity Application created"