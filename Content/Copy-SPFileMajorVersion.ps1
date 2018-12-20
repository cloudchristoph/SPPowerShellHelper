<#
.SYNOPSIS
    Copies a major version to a new library.
.DESCRIPTION
    Copies a major version to a new library.
.NOTES
    File Name  : Copy-SPFileMajorVersion.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Copy-SPFileMajorVersion.ps1 -WebUrl "http://test.dev.local" -SourceListName "SourceList" -TargetListName "Documents" -ItemId 12
    Copy-SPFileMajorVersion.ps1 -WebUrl "http://test.dev.local" -SourceListName "SourceList" -TargetListName "Documents" -ItemId 12 -UseMajorVersion 7
.PARAMETER WebUrl
    The url of the web.
.PARAMETER SourceListName
    The name of the source list.
.PARAMETER TargetListName
    The name of the target list.
.PARAMETER ItemId
    The id of the item to be copied.
.PARAMETER UseMajorVersion
    The major version to copy if it is not the latest one.
    Default is 0 so the latest is used.
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
    $WebUrl,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SourceListName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $TargetListName,

    [Parameter(Mandatory=$true)]
    [int]
    $ItemId,

    [Parameter(Mandatory=$false)]
    [int]
    $UseMajorVersion = 0
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

Write-Verbose "Loading web $WebUrl"
$web = Get-SPWeb $WebUrl
Write-Verbose "Loading source list $SourceListName"
$sourceList = $web.Lists[$SourceListName]
if($null -eq $sourceList)
{
    Write-Error "Could not find source list"
    $web.Dispose()
    exit
}
Write-Verbose "Loading item $ItemId"
$item = $sourceList.Items.GetItemById($ItemId)
if($null -eq $item)
{
    Write-Error "Could not find source item"
    $web.Dispose()
    exit
}

$file = $item.File
if($null -eq $file)
{
    Write-Error "Could not find file"
    $web.Dispose()
    exit
}

if($file.MajorVersion -lt 1)
{
    Write-Error "No published version found for file $($file.Name)."
    $web.Dispose()
    exit
}

if($UseMajorVersion -lt 1 -or $UseMajorVersion -gt $file.MajorVersion)
{
    Write-Verbose "Major version $UseMajorVersion to low or bigger than existing major version. Version $($file.MajorVersion) used instead."
    $UseMajorVersion = $file.MajorVersion
}

$versionLabel = "$($UseMajorVersion).0"
Write-Verbose "Loading version $versionLabel"
$fileVersion = $file.Versions.GetVersionFromLabel($versionLabel)
Write-Verbose "File version $versionLabel found"

$targetList = $web.Lists[$TargetListName]
if($null -eq $targetList)
{
    Write-Error "Could not find target list"
    $web.Dispose()
    exit
}

$uploadList = $web.GetFolder($TargetListName)
$uploadedFile = $uploadList.Files.Add($targetList.RootFolder.ServerRelativeUrl.Substring(1) + "/" + $item.Name, $fileVersion.OpenBinaryStream(), $false)
Write-Verbose "File $($uploadedFile.ServerRelativeUrl) uploaded to web $WebUrl"

$web.Dispose()