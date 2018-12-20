<#
.SYNOPSIS
    Sets the alternate css url of a single web or all webs within a site collection.
.DESCRIPTION
    Sets the alternate css url of a single web or all webs within a site collection.
.NOTES
    File Name  : Set-SPAlternateCssUrl.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Set-SPAlternateCssUrl.ps1 -WebUrl "http://test.dev.local/subweb" -CssUrl "/subWeb/SiteAssets/custom.css"
    Set-SPAlternateCssUrl.ps1 -SiteUrl "http://test.dev.local" -CssUrl "/SiteAssets/custom.css"
.PARAMETER WebUrl
    The url of the web to set the alternate css url.
.PARAMETER SiteUrl
    The url of the site collection to set the alternate css url to all webs.
.PARAMETER CssUrl
    The url of the CSS to set.
#>

##############################
#
# Parameters
#
##############################

param(
    [Parameter(Mandatory=$true, ParameterSetName="SingleWeb")]
    [ValidateNotNullOrEmpty()]
    [string]
    $WebUrl,

    [Parameter(Mandatory=$true, ParameterSetName="WholeSiteCollection")]
    [ValidateNotNullOrEmpty()]
    [string]
    $SiteUrl,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CssUrl
)

##############################
#
# Snapins
#
##############################

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

##############################
#
# Functions
#
##############################

function SetCss{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $url,

        [Parameter(Mandatory=$true)]
        [string]
        $css
    )

    $web = Get-SPWeb $url
    $unsafeUpates = $web.AllowUnsafeUpdates
    $web.AllowUnsafeUpdates = $true
    $web.AlternateCssUrl = $css
    $web.Update()
    $web.AllowUnsafeUpdates = $unsafeUpates
    $web.Dispose()
}

##############################
#
# Main
#
##############################

if($PSCmdlet.ParameterSetName -eq "SingleWeb")
{
    $site = Get-SPSite $SiteUrl
    SetCss -url $site.RootWeb.Url -css $CssUrl
    $site.Dispose()
}

if($PSCmdlet.ParameterSetName -eq "WholeSiteCollection")
{
    SetCss -url $WebUrl -css $CssUrl
}