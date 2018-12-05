<#
.SYNOPSIS
    Sends an email from a SharePoint server.
.DESCRIPTION
    Sends an email from a SharePoint server.
    Needs to run an o SharePoint server with an installed SMTP.
.NOTES
    File Name  : Send-SPMail.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Send-SPMail.ps1 -WebUrl "http://test.dev.local" -RecipientMail "test@dev.local" -FromMail "spadmin@dev.local"
.PARAMETER WebUrl
    The url of the SharePoint web.
.PARAMETER RecipientMail
    The recipient of the mail.
.PARAMETER FromMail
    The from address of the mail.
.PARAMETER Subject
    The subject of the mail.
    Default is "Hello world".
.PARAMETER Body
    The body of the mail.
    Default is "Hello world.".
#>

##############################
#
# Parameters
#
##############################

param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $WebUrl,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RecipientMail,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $FromMail,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Subject = "Hello world",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Body = "Hello world."
)

##############################
#
# Snapins
#
##############################

Add-PSSnapin Microsoft.SharePoint.PowerShell

##############################
#
# Main
#
##############################

$web = Get-SPWeb $WebUrl
$headers = New-Object System.Collections.Specialized.StringDictionary
$headers.Add("to", $RecipientMail)
#$headers.Add("cc", "cc1@domain.com")        
#$headers.Add("bcc", "bcc1@domain.com")        
$headers.Add("from", $FromMail)
$headers.Add("subject", $Subject)
$headers.Add("content-type", "text/html")
[Microsoft.SharePoint.Utilities.SPUtility]::SendEmail($web, $headers, $Body)
$web.Dispose()