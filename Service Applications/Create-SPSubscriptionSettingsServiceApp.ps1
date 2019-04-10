<#
.SYNOPSIS
    Creates a new service application of type: Subscription Settings Service.
.DESCRIPTION
    Creates a new service application of type: Subscription Settings Service.
    Creates a new service application proxy.
    Creates a new application pool if there is no existing one.
.NOTES
    File Name  : Create-SPSubscriptionSettingsServiceApp.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Create-SPSubscriptionSettingsServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_SubscriptionSettingsService"
    Create-SPSubscriptionSettingsServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_SubscriptionSettingsService" -ServiceAppName "Subscription Service"
    Create-SPSubscriptionSettingsServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_SubscriptionSettingsService" -ServiceAppName "Subscription Service" -AppPoolName "Existing AppPool Shared"
    Create-SPSubscriptionSettingsServiceApp.ps1 -DatabaseServer SP16_SQL -DatabaseName "SP16_ServiceApp_SubscriptionSettingsService" -ServiceAppName "Subscription Service" -AppPoolName "New AppPool Subscription" -ManagedAccount "DEV\SP_Services"
.PARAMETER ManagedAccount
    The managed account to be used for a new application pool. If you want to create a new application pool you have to specify a managed account.
    Needs to be in the following format: DOMAIN\USER
.PARAMETER AppPoolName
    The name of the existing or new application pool. If you want to create a new application pool you have to specify a managed account.
    Default is "AppPool_SubscriptionSettings".
.PARAMETER ServiceAppName
    The name of the new service application.
    Default is "Subscription Settings Service Application".
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
    $AppPoolName = "AppPool_SubscriptionSettings",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ServiceAppName = "Subscription Settings Service Application",

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

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

##############################
#
# Main
#
##############################

# Error handling

$subscriptionServiceApp = Get-SPServiceApplication | where { $_.TypeName -like "Microsoft SharePoint Foundation Subscription Settings Service Application" } -ErrorAction SilentlyContinue
if ($null -ne $subscriptionServiceApp) {
    Write-Error "Service Application of type Microsoft SharePoint Foundation Subscription Settings Service Application already exists!"
    exit
}

$subscriptionServiceApp = Get-SPServiceApplication -Name $ServiceAppName -ErrorAction SilentlyContinue
if ($null -ne $subscriptionServiceApp) {
    Write-Error "Service Application with name $ServiceAppName already exists!"
    exit
}

# Start service instance

Write-Verbose "Starting service instance"
$si = Get-SPServiceInstance | where {$_.TypeName -like "Microsoft SharePoint Foundation Subscription Settings Service"}
$si | Start-SPServiceInstance

do {
    $si = Get-SPServiceInstance | where {$_.TypeName -like "Microsoft SharePoint Foundation Subscription Settings Service"}
    Write-Host "Waiting for provisioning. Current state: $($si.Status)"
    Start-Sleep -Seconds 5
}while ($si.Status -ne "Online")

Write-Verbose "Service instance started"

# Get or create app pool

Write-Verbose "Getting existing Application  Pool"
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
$subscriptionServiceApp = New-SPSubscriptionSettingsServiceApplication -ApplicationPool $appPool -Name $ServiceAppName -DatabaseName $DatabaseName -DatabaseServer $DatabaseServer
Write-Verbose "Service Application created"

Write-Verbose "Creating Service Application Proxy"
$subscriptionProxyServiceApp = New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $subscriptionServiceApp
Write-Verbose "Service Application Proxy created"

Write-Host "Subscription Settings Service Application created"