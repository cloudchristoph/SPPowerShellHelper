<#
.SYNOPSIS
    Creates a new service application of type: User Profile Service.
.DESCRIPTION
    Creates a new service application of type: User Profile Service.
    Creates a new service application proxy.
    Creates a new application pool if there is no existing one.
.NOTES
    File Name  : Create-SPUpsServiceApp.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Create-SPUpsServiceApp.ps1 -DatabaseServer SP16_SQL -ProfileDBName "SP16_ServiceApp_UpsService_Profile" -ProfileSyncDBName "SP16_ServiceApp_UpsService_Sync" -ProfileSocialDBName "SP16_ServiceApp_UpsService_Social" -MySiteHostLocation "http://mysites.dev.local/" -MySiteManagedPath "personal"
    Create-SPUpsServiceApp.ps1 -DatabaseServer SP16_SQL -ProfileDBName "SP16_ServiceApp_UpsService_Profile" -ProfileSyncDBName "SP16_ServiceApp_UpsService_Sync" -ProfileSocialDBName "SP16_ServiceApp_UpsService_Social" -MySiteHostLocation "http://mysites.dev.local/" -MySiteManagedPath "personal" -ServiceAppName "UPS Service"
    Create-SPUpsServiceApp.ps1 -DatabaseServer SP16_SQL -ProfileDBName "SP16_ServiceApp_UpsService_Profile" -ProfileSyncDBName "SP16_ServiceApp_UpsService_Sync" -ProfileSocialDBName "SP16_ServiceApp_UpsService_Social" -MySiteHostLocation "http://mysites.dev.local/" -MySiteManagedPath "personal" -ServiceAppName "UPS Service" -AppPoolName "Existing AppPool Shared"
    Create-SPUpsServiceApp.ps1 -DatabaseServer SP16_SQL -ProfileDBName "SP16_ServiceApp_UpsService_Profile" -ProfileSyncDBName "SP16_ServiceApp_UpsService_Sync" -ProfileSocialDBName "SP16_ServiceApp_UpsService_Social" -MySiteHostLocation "http://mysites.dev.local/" -MySiteManagedPath "personal" -ServiceAppName "UPS Service" -AppPoolName "New AppPool App" -ManagedAccount "DEV\SP_Services"
.PARAMETER ManagedAccount
    The managed account to be used for a new application pool. If you want to create a new application pool you have to specify a managed account.
    Needs to be in the following format: DOMAIN\USER
.PARAMETER AppPoolName
    The name of the existing or new application pool. If you want to create a new application pool you have to specify a managed account.
    Default is "AppPool_UPS".
.PARAMETER ServiceAppName
    The name of the new service application.
    Default is "User Profile Service Application".
.PARAMETER DatabaseServer
    The name of the database server. Normally the SQL Alias.
.PARAMETER ProfileDBName
    The name of the new database for user profiles.
.PARAMETER ProfileSyncDBName
    The name of the new database for user profiles sync.
.PARAMETER ProfileSocialDBName
    The name of the new database for user profiles social.
.PARAMETER MySiteHostLocation
    The MySite Host location.
.PARAMETER MySiteManagedPath
    The MySite managed path.
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
    $AppPoolName = "AppPool_UPS",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ServiceAppName = "User Profile Service Application",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DatabaseServer,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ProfileDBName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ProfileSyncDBName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ProfileSocialDBName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ ($_.StartsWith("http://") -or $_.StartsWith("https://")) -and $_.EndsWith("/") })]
    [string]
    $MySiteHostLocation,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $MySiteManagedPath
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

$upsServiceApp = Get-SPServiceApplication | where {$_.TypeName -like "User Profile Service Application"} -ErrorAction SilentlyContinue
if ($null -ne $upsServiceApp) {
    Write-Error "Service Application of type User Profile Service Application already exists!"
    exit
}

$upsServiceApp = Get-SPServiceApplication -Name $ServiceAppName -ErrorAction SilentlyContinue
if ($null -ne $upsServiceApp) {
    Write-Error "Service Application with name $ServiceAppName already exists!"
    exit
}

# Start service instance

Write-Verbose "Starting service instance"
$si = Get-SPServiceInstance | where {$_.TypeName -like "User Profile Service"}
$si | Start-SPServiceInstance

do {
    $si = Get-SPServiceInstance | where {$_.TypeName -like "User Profile Service"}
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
$upsServiceApp = New-SPProfileServiceApplication -ApplicationPool $appPool -Name $ServiceAppName `
                                                 -ProfileDBServer $DatabaseServer -ProfileDBName $ProfileDBName `
                                                 -SocialDBServer $DatabaseServer -SocialDBName $ProfileSocialDBName `
                                                 -ProfileSyncDBServer $DatabaseServer -ProfileSyncDBName $ProfileSyncDBName `
                                                 -MySiteHostLocation $MySiteHostLocation -MySiteManagedPath $MySiteManagedPath
Write-Verbose "Service Application created"

Write-Verbose "Creating Service Application Proxy"
$bdcProxyServiceApp = New-SPProfileServiceApplicationProxy -ServiceApplication $upsServiceApp -Name $($ServiceAppName + " Proxy")
Write-Verbose "Service Application Proxy created"

Write-Host "User Profile Service Application created"