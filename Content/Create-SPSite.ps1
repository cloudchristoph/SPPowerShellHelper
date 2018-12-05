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
    $Url,

    [Parameter(Mandatory=$false)]
    [string]
    $ContentDB = "",

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Name,

    [Parameter(Mandatory=$false)]
    [string]
    $Description = "",

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Template,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $PrimaryLogin,

    [Parameter(Mandatory=$false)]
    [string]
    $SecondaryLogin,

    [Parameter(Mandatory=$false)]
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

if([string]::IsNullOrEmpty($SecondaryLogin))
{
    $SecondaryLogin = $PrimaryLogin
}

if([string]::IsNullOrEmpty($ContentDB))
{
    New-SPSite -Url $Url -Name $Name –Description $Description -Template $Template -OwnerAlias $PrimaryLogin -Language $Language -SecondaryOwnerAlias $SecondaryLogin
}
else{
    New-SPSite -Url $Url –ContentDatabase $ContentDB -Name $Name –Description $Description -Template $Template -OwnerAlias $PrimaryLogin -Language $Language -SecondaryOwnerAlias $SecondaryLogin
}

$web = Get-SPWeb $Url
if ($web -ne $null -and $web.AssociatedVisitorGroup -eq $null) {
    Write-Verbose 'The Visitor Group does not exist. It will be created...' -ForegroundColor DarkYellow
    $currentLogin = $web.CurrentUser.LoginName

    if ($web.CurrentUser.IsSiteAdmin -eq $false){
        Write-Host ('The user '+$currentLogin+' needs to be a SiteCollection administrator, to create the default groups.') -ForegroundColor Red
        return
    }

    $web.CreateDefaultAssociatedGroups($currentLogin, $currentLogin, [System.String].Empty)
    Write-Verbose 'The default Groups have been created.' -ForegroundColor Green
} else {
    Write-Verbose 'The Visitor Group already exists.' -ForegroundColor Green
}
$web.Dispose()