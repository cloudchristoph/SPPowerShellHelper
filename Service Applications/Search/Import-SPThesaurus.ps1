<#
.SYNOPSIS
    Imports a file for thesaurus.
.DESCRIPTION
    Imports a file for thesaurus.
.NOTES
    File Name  : Import-SPThesaurus.ps1
    Author     : Henrik Krumbholz
.EXAMPLE
    Import-SPThesaurus.ps1 -FilePath "C:\tmp\thesaurus.csv"
.PARAMETER FilePath
    The path to the CSV-file of the thesaurus.
    Needs to be full qualified.
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
    $FilePath
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

$title = "New Thesaurus"
$message = "The script is going to overwrite the existing thesaurus. Are you sure you want to proceed?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Deletes all the files in the folder."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retains all the files in the folder."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {
            Write-Verbose "Getting search service application"
            $searchApp = Get-SPEnterpriseSearchServiceApplication
            if($null -eq $searchApp)
            {
                Write-Error "No search service application found"
                exit
            }
            
            Write-Verbose "Importing thesaurus"
            Import-SPEnterpriseSearchThesaurus -SearchApplication $searchApp -Filename $FilePath
            Write-Verbose "Thesaurus imported"
        }
        1 {
        }
    }