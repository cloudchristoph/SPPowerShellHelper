<#
.SYNOPSIS  
    Creates audiences in the current user profile service.
.DESCRIPTION  
    Creates audiences in the current user profile service. Does not update existing audiences.
.NOTES
    The executing account needs full control on the user profile service.
    https://msdn.microsoft.com/en-us/library/ms578007.aspx
    File Name  : New-SPAudienceUserProfile.ps1
    Author     : Henrik Krumbholz
.EXAMPLE  
    New-SPAudienceUserProfile.ps1 -MySiteHostUrl http://my.dev.local -Name "NewAudience" -AudienceRules @(@{Left = "Something"; Operation = "AND"; Right = "Anything"; })
.PARAMETER MySiteHostUrl
    The url of the MySite host.
.PARAMETER Name
    The name of the audience to be created.
.PARAMETER Description
    The description of the audience to be created.
    Default is the Name.
.PARAMETER Owner
    The owner of the audience to be created. Use the format <DOMAIN\USERACCOUNT>.
.PARAMETER AudienceGroupOperation
    The group operation of the audience to be created.
    Default is AUDIENCE_AND_OPERATION.
.PARAMETER AudienceRules
    The audience rules to be added. Needs to be in the format: @(@{Left = "Something"; Operation = "AND"; Right = "Anything"; })
#>


##############################
#
# Parameters
#
##############################

param(
    [Parameter(Mandatory=$true)]
    [string]
    $MySiteHostUrl,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Name,
    
    [Parameter(Mandatory=$false)]
    [string]
    $Description = $Name,
    
    [Parameter(Mandatory=$false)]
    [string]
    $Owner,
    
    [Parameter(Mandatory=$false)]
    [Microsoft.Office.Server.Audience.AudienceGroupOperation]
    $AudienceGroupOperation = [Microsoft.Office.Server.Audience.AudienceGroupOperation]::AUDIENCE_AND_OPERATION,
    
    [Parameter(Mandatory=$true)]
    [Object[]]
    $AudienceRules
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

$mySiteHost = Get-SPSite $MySiteHostUrl
$context = Get-SPServiceContext $mySiteHost
$audmgr = New-Object Microsoft.Office.Server.Audience.AudienceManager($context)

try
{
    $audience = $AudienceManager.GetAudience($Name)
}
catch{}
if($null -ne $audience)
{
    Write-Verbose "Audience $Name already exists. No audience is created."
    return
}

if([string]::IsNullOrEmpty($Owner))
{
    $audience = $audmgr.Audiences.Create($Name, $Description)
    $audience.GroupOperation = $AudienceGroupOperation
}
else
{
    $audience = $audmgr.Audiences.Create($Name, $Description, $Owner, $AudienceGroupOperation)
}

try
{
    $newRules = New-Object System.Collections.ArrayList
    $AudienceRules | ForEach-Object {
        $rule = New-Object Microsoft.Office.Server.Audience.AudienceRuleComponent($_.Left, $_.Operation, $_.Right)
        $newRules.Add($rule)
    }
    
    $audience.AudienceRules = $newRules
    $audience.Commit()
}
catch
{
    Write-Host $_.Exception
    Write-Host "Could not create Audience $Name" -ForegroundColor Red
}

$mySiteHost.Dispose()