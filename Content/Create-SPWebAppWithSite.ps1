<#
.SYNOPSIS  
    Creates a web application and a sitecollection within a specific content database.
.DESCRIPTION  
    Creates a web application and a site collection within a specific content database, with a specific template, language id, url and name.
    Creates the default associated groups.
    Does not create a host header.
.NOTES
    File Name  : Create-SPWebAppWithSite.ps1
    Author     : Henrik Krumbholz
.EXAMPLE  
    Create-SPWebAppWithSite.ps1 -Url "http://sp.dev.local/" -Name "NewWebApp" -AppPoolName "ContentAppPool" -AppPoolAccountName "DEV\SVC_AppPool" -PrimaryLogin "DEV\admin"
    Create-SPWebAppWithSite.ps1 -Url "http://sp.dev.local/" -Name "NewWebApp" -AppPoolName "ContentAppPool" -AppPoolAccountName "DEV\SVC_AppPool" -PrimaryLogin "DEV\admin" -DBServer "SPDEV"
    Create-SPWebAppWithSite.ps1 -Url "http://sp.dev.local/" -Name "NewWebApp" -AppPoolName "ContentAppPool" -AppPoolAccountName "DEV\SVC_AppPool" -PrimaryLogin "DEV\admin" -DBServer "SPDEV" -ContentDB "TargetContentDB"
    Create-SPWebAppWithSite.ps1 -Url "http://sp.dev.local/" -Name "NewWebApp" -AppPoolName "ContentAppPool" -AppPoolAccountName "DEV\SVC_AppPool" -PrimaryLogin "DEV\admin" -DBServer "SPDEV" -ContentDB "TargetContentDB" -Language 1031
    Create-SPWebAppWithSite.ps1 -Url "http://sp.dev.local/" -Name "NewWebApp" -AppPoolName "ContentAppPool" -AppPoolAccountName "DEV\SVC_AppPool" -PrimaryLogin "DEV\admin" -DBServer "SPDEV" -ContentDB "TargetContentDB" -Language 1031 
    Create-SPWebAppWithSite.ps1 -Url "http://sp.dev.local/" -Name "NewWebApp" -AppPoolName "ContentAppPool" -AppPoolAccountName "DEV\SVC_AppPool" -PrimaryLogin "DEV\admin" -DBServer "SPDEV" -ContentDB "TargetContentDB" -Language 1031 -Description "Site Description" -SiteCollectionTemplate "BLOG#0"
    Create-SPWebAppWithSite.ps1 -Url "http://sp.dev.local/" -Name "NewWebApp" -AppPoolName "ContentAppPool" -AppPoolAccountName "DEV\SVC_AppPool" -PrimaryLogin "DEV\admin" -DBServer "SPDEV" -ContentDB "TargetContentDB" -Language 1031 -Description "Site Description" -SiteCollectionTemplate "BLOG#0" -HostHeader "sp.dev.local"
.PARAMETER Url
    The url of the new site to be created. Needs to be full qualified.
.PARAMETER ContentDB
    The name of the target content database. If empty SharePoint is going to choose the content database.
.PARAMETER Name
    The name of the new site to be created.
.PARAMETER Description
    The description of the new site to be created.
.PARAMETER Template
    The template of the new site to be created. Needs to be noted as <WebTemplate#WebTemplateId>. For example: STS#1
.PARAMETER PrimaryLogin
    The primary site collection administrator of the new site to be created. Needs to be noted as <Domain\Account>.
.PARAMETER SecondaryLogin
    The secondary site collection administrator of the new site to be created. Needs to be noted as <Domain\Account>.
.PARAMETER Language
    The language code of the new site to be created. Default is 1033 (en).
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
    $Name,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AppPoolName,

    [Parameter(Mandatory=$true)]
    [string]
    $AppPoolAccountName,

    [Parameter(Mandatory=$true)]
    [ValidateScript({ ($_.StartsWith("http://") -or $_.StartsWith("https://")) -and $_.EndsWith("/") })]
    [string]
    $Url,
    
    [Parameter(Mandatory=$false)]
    [string]
    $DBServer,
    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ContentDB = "WSS_Content_$([Guid]::NewGuid().ToString())",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $Port = 80,

    [Parameter(Mandatory=$false)]
    [string]
    $HostHeader,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SiteCollectionTemplate = "STS#0",

    [Parameter(Mandatory = $false)]
    [string]
    $Description = "",
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $PrimaryLogin,

    [Parameter(Mandatory = $false)]
    [string]
    $SecondaryLogin,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Language = 1033
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

Write-Verbose "Checking for existing web application"
$webApp = Get-SPWebApplication | where Url -eq $Url
if($null -ne $webApp)
{
    Write-Error "WebApplication with url $Url already exists."
    exit
}

Write-Verbose "Getting application pool."
$appPool = Get-SPServiceApplicationPool -Identity $AppPoolName -ErrorAction SilentlyContinue
if($null -eq $appPool)
{
    Write-Verbose "No application pool with name $AppPoolName found. A new one is going to be created."
}
else
{
    Write-Error "Application pool $AppPoolName already exists."
    exit
}

if($null -eq $appPool)
{
    Write-Verbose "Getting application pool account."
    $managedAccount = Get-SPManagedAccount $AppPoolAccountName
    if($null -eq $managedAccount)
    {
        Write-Error "No managed account found with name $AppPoolAccountName."
        exit
    }
}

Write-Verbose "Creating new web application"

$newParams = @{
    Name = $Name
    ApplicationPool = $AppPoolName
    Url = $Url
    Port = $Port
}

if($null -eq $appPool)
{
    $newParams.Add("ApplicationPoolAccount", $managedAccount)
    
}
if(-not [string]::IsNullOrEmpty($DBServer))
{
    $newParams.Add("DatabaseServer", $DBServer)
}
if(-not [string]::IsNullOrEmpty($ContentDB))
{
    $newParams.Add("DatabaseName", $ContentDB)
}
if(-not [string]::IsNullOrEmpty($HostHeader))
{
    $newParams.Add("HostHeader", $HostHeader)
}

New-SPWebApplication @newParams | Out-Null

Write-Verbose "New web application $Name created"

# Create site collection

Write-Verbose "Creating root site collection"

if ([string]::IsNullOrEmpty($SecondaryLogin)) {
    $SecondaryLogin = $PrimaryLogin
}

if ([string]::IsNullOrEmpty($ContentDB)) {
    New-SPSite -Url $Url -Name $Name -Description $Description -Template $SiteCollectionTemplate -OwnerAlias $PrimaryLogin -Language $Language -SecondaryOwnerAlias $SecondaryLogin | Out-Null
}
else {
    New-SPSite -Url $Url -ContentDatabase $ContentDB -Name $Name -Description $Description -Template $SiteCollectionTemplate -OwnerAlias $PrimaryLogin -Language $Language -SecondaryOwnerAlias $SecondaryLogin | Out-Null
}

$web = Get-SPWeb $Url
if ($web -ne $null -and $web.AssociatedVisitorGroup -eq $null) {
    Write-Verbose 'The Visitor Group does not exist. It will be created...'
    [Microsoft.SharePoint.SPSecurity]::RunWithElevatedPrivileges(
        {
            $tmpWeb = Get-SPWeb $Url
            $tmpWeb.CreateDefaultAssociatedGroups($PrimaryLogin, $SecondaryLogin, [System.String].Empty)
            $tmpWeb.Dispose()
        }
    )
    Write-Verbose 'The default Groups have been created.'
}
else {
    Write-Verbose 'The Visitor Group already exists.'
}
$web.Dispose()

Write-Verbose "Root site collection created"