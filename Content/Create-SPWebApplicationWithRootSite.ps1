<#
.SYNOPSIS  
    Creates a site collection within a specific content database.
.DESCRIPTION  
    Creates a site collection within a specific content database, with a specific template, language id, url and name.
    Creates the default associated groups.
.NOTES
    File Name  : Create-SPSite.ps1
    Author     : Henrik Krumbholz
.EXAMPLE  
    Create-SPSite.ps1 -Url "http://sp.dev.local/newSite" -Name "NewSite" -Template "STS#1" -PrimaryLogin "dev\admin"
    Create-SPSite.ps1 -Url "http://sp.dev.local/newSite" -Name "NewSite" -Template "STS#1" -PrimaryLogin "dev\admin" -ContentDB "TargetContentDB"
    Create-SPSite.ps1 -Url "http://sp.dev.local/newSite" -Name "NewSite" -Template "STS#1" -PrimaryLogin "dev\admin" -ContentDB "TargetContentDB" -Language 1031
    Create-SPSite.ps1 -Url "http://sp.dev.local/newSite" -Name "NewSite" -Template "STS#1" -PrimaryLogin "dev\admin" -ContentDB "TargetContentDB" -Language 1031 -SecondaryLogin "dev\secondAdmin"
    Create-SPSite.ps1 -Url "http://sp.dev.local/newSite" -Name "NewSite" -Template "STS#1" -PrimaryLogin "dev\admin" -ContentDB "TargetContentDB" -Language 1031 -SecondaryLogin "dev\secondAdmin" Description "Site Description"
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

    [Parameter(Mandatory=$false)]
    [string]
    $AppPoolAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]
    $DBServer,
    
    [Parameter(Mandatory=$false)]
    [string]
    $ContentDB,

    [Parameter(Mandatory=$false)]
    [integer]
    $Port,

    [Parameter(Mandatory=$false)]
    [string]
    $Url,

    [Parameter(Mandatory=$false)]
    [string]
    $HostHeader,

    [Parameter(Mandatory=$false)]
    [string]
    $IISPath,

    [Parameter(Mandatory=$false)]
    [string]
    $SiteCollectionTemplate
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

#Variables
#$AppPoolAccount = "DOMAIN\App_Pool_Account" #The Application Pool domain account, must already be created as a SharePoint managed account
#$ApplicationPoolName ="Publishing AppPool" #This will create a new Application Pool
#$ContentDatabase = "SP_ContentDB_publishing2016" #Content DB
#$DatabaseServer = "SP2016-DB" #Alias of your DB Server
#$WebApp = "http://publishing2016.contoso.com" #The name of your new Web Application
#$HostHeader = "publishing2016.contoso.com" #The IIS host header
#$Url = $WebApp
#$Description = "SharePoint 2016 Publishing Site"
#$IISPath = "D:\inetpub\wwwroot\wss\VirtualDirectories\publishing2016.contoso.com80" #The path to IIS directory
#$SiteCollectionTemplate = "BLANKINTERNETCONTAINER#0"  #Publishing Site with Workflow Template

Write-Verbose "Getting application pool."
$appPool = Get-SPServiceApplicationPool -Identity $AppPoolName
if($null -eq $appPool)
{
    Write-Verbose "No application pool with name $AppPoolName found. A new one is going to be created."
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

if($null -eq $appPool)
{
    New-SPWebApplication -ApplicationPool $AppPoolName `
                        -ApplicationPoolAccount $managedAccount `
                        -Name $Name `
                        -AuthenticationProvider (New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication) `
                        -DatabaseName $ContentDB `
                        -DatabaseServer $DBServer `
                        -HostHeader $HostHeader `
                        -Path $IISPath `
                        -Port $Port `
                        -URL $Url
}