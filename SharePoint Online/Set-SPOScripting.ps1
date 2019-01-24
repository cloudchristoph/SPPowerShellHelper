<#
.SYNOPSIS
    Enables scripting for a specific site.
.DESCRIPTION
    Enables scripting for a specific site.
.NOTES
    File Name  : Set-SPOScripting.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Set-SPOScripting.ps1 -AdminTenantUrl "http://dev-admin.sharepoint.de" -UrlToAllow "http://dev.sharepoint.de/sites/test" -CloudProvider GermanCloud
    Set-SPOScripting.ps1 -AdminTenantUrl "http://dev-admin.sharepoint.com" -UrlToAllow "http://dev.sharepoint.com/sites/test" -CloudProvider O365
.PARAMETER AdminTenantUrl
    The url of the admin tenant.
.PARAMETER CloudProvider
    The cloud provider to connect to.
    Default is O365.
.PARAMETER UrlToAllow
    The url to allow scripting.
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
    $AdminUrl,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("GermanCloud","O365")]
    [string]
    $CloudProvider = "O365",

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $UrlToAllow
)

##############################
#
# Main
#
##############################

$userCredential = Get-Credential

switch($CloudProvider) {
    "GermanCloud" {
        Write-Verbose "Connecting to $AdminUrl"
        Connect-PnPOnline -Url $AdminUrl -UseWebLogin
        $tenantSite = Get-PnPTenantSite | where { $_.Url -eq $UrlToAllow }
        if($null -eq $tenantSite -or $tenantSite.Count -ne 1)
        {
            Write-Error "Non site with url $UrlToAllow found"
            return
        }
        Write-Verbose "Getting client context"
        $ctx = Get-PnPContext
        Write-Verbose "Setting DenyAddAndCustomizePages to disabled"
        $tenantsite.DenyAddAndCustomizePages = [Microsoft.Online.SharePoint.TenantAdministration.DenyAddAndCustomizePagesStatus]::Disabled
        $tenantsite.Update()
        $ctx.ExecuteQuery()
        Write-Verbose "Setting changes"
        Write-Verbose "Disconnecting"
        Disconnect-PnPOnline
        Write-Verbose "Disconnected"
        break
    }
    "O365" {
        Write-Verbose "Connecting to $AdminUrl"
        Connect-SPOService -Url $AdminUrl -Credential $userCredential
        Write-Verbose "Setting DenyAddAndCustomizePages to disabled"
        Set-SPOSite $UrlToAllow -DenyAddAndCustomizePages 0
        Write-Verbose "Disconnecting"
        Disconnect-SPOService
        Write-Verbose "Disconnected"
        break
    }
}
