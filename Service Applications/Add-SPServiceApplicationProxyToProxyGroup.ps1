<#
.SYNOPSIS
    Adds a service application proxy to a proxy group.
.DESCRIPTION
    Adds a service application proxy to a proxy group.
.NOTES
    File Name  : Add-SPServiceApplicationProxyToProxyGroup.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Add-SPServiceApplicationProxyToProxyGroup.ps1 -ProxyGroupName "[default]" -ProxyName "Search Service Application Proxy"
    Add-SPServiceApplicationProxyToProxyGroup.ps1 -UseDefaultProxyGroup -ProxyName "Search Service Application Proxy"
.PARAMETER ProxyGroupName
    The name of the proxy group to add the proxy to.
.PARAMETER ProxyName
    The name of the proxy to add.
#>

##############################
#
# Parameters
#
##############################

param(
    [Parameter(Mandatory = $true, ParameterSetName = "ProxyGroup")]
    [ValidateNotNullorEmpty()]
    [string]
    $ProxyGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]
    $ProxyName,

    [Parameter(Mandatory = $true, ParameterSetName = "DefaultProxyGroup")]
    [switch]
    $UseDefaultProxyGroup
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

if ($UseDefaultProxyGroup) {
    $ProxyGroupName = "[default]"
}

Write-Verbose "Getting Proxy Group"
$proxyGroup = Get-SPServiceApplicationProxyGroup | Where-Object FriendlyName -eq $ProxyGroupName
Write-Verbose "Getting Proxy"
$proxy = Get-SPServiceApplicationProxy | Where-Object Name -eq $ProxyName
if ($null -ne $proxyGroup -and $null -ne $proxy) {
    $addedGroup = Add-SPServiceApplicationProxyGroupMember -Identity $proxyGroup -Member $proxy
    Write-Verbose "Proxy $ProxyName added to Proxy Group $ProxyGroupName."
}
else {
    Write-Error "Could not find Proxy Group $ProxyGroupName or Proxy $ProxyName."
}