<#
.SYNOPSIS
    Sets the maximum upload limit of a web application.
.DESCRIPTION
    Sets the maximum upload limit of a web application.
.NOTES
    File Name  : Set-SPWebApplicationUploadLimit.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Set-SPWebApplicationUploadLimit.ps1 -WebApplication $webApp -Size 1024
    Get-SPWebApplication | Set-SPWebApplicationUploadLimit.ps1 -Size 1024
.PARAMETER WebApplication
    The web application to update.
.PARAMETER Size
    The size of the upload limit in MB.
#>

##############################
#
# Parameters
#
##############################

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeLine=$true, Position=0)]
    [Microsoft.SharePoint.PowerShell.SPWebApplicationPipeBind]
    $WebApplication,
    
    [Parameter(Mandatory=$true)]
    [ValidateScript({$_ -gt 0 })]
    [int]
    $Size
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

$webApp = $WebApplication.Read()

if($webApp)
{
    $webApp.MaximumFileSize = $Size
    $webApp.Update()
         
    Write-Verbose "Maximum File Upload Size has been updated to $Size MB!"
}
else
{
    Write-Error "No valie web application"
}