<#
.SYNOPSIS
    Exports security findings from Graph to a CSV file
.DESCRIPTION
    Exports security findings from Graph to a CSV file. If the csv file already exists, the script stops execution, 
    unless the -Force parameter is used
.PARAMETER SubscriptionId
    [Optional] Array of strings containing one or more subscription ids that the security findings should be exported for.
    If left empty, the tenantscope is used, exporting for all subscriptions
.PARAMETER ExportPath
    [Optional] Path to create the csv file in. Uses the script location if omitted
.PARAMETER ExportFileName
    [Optional] Name for the export csv file. Defaults to securityfindings-dd-mm-YYYY.csv
.PARAMETER Delimiter
    [Optional] Delimeter to use in the csv file. Defaults to ';'
.PARAMETER Force
    [Optional] Overwrite the csv file if it already exists
.EXAMPLE
    Export-AzSecurityFindings.ps1
    Export security findings for all subscriptions within the tenant scope
.EXAMPLE
    Export-AzSecurityFindings.ps1 -SubscriptionId <GUID>,<GUID>
    Export security findings for the supplied subscription ids
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [String[]]
    $SubscriptionId = "",

    [Parameter(Mandatory=$false)]
    [String]
    $ExportPath = $PSScriptRoot,

    [Parameter(Mandatory=$false)]
    [String]
    $ExportFileName = ("securityfindings-{0}.csv" -f (Get-Date -UFormat %d-%m-%Y)),

    [Parameter(Mandatory=$false)]
    [String]
    $Delimiter = ";",

    [Parameter(Mandatory=$false)]
    [Switch]
    $Force
)

$firstRun = $true

# https://techcommunity.microsoft.com/t5/microsoft-defender-for-cloud/exporting-vulnerability-assessment-results-in-microsoft-defender/ba-p/1212091
$query = @"
securityresources
 | where type == "microsoft.security/assessments"
 | where * contains "Machines should have vulnerability findings resolved"
 | summarize by assessmentKey=name //the ID of the assessment
 | join kind=inner (
    securityresources
     | where type == "microsoft.security/assessments/subassessments"
     | extend assessmentKey = extract(".*assessments/(.+?)/.*",1,  id)
 ) on assessmentKey
| project assessmentKey, subassessmentKey=name, id, parse_json(properties), resourceGroup, subscriptionId, tenantId
| extend description = properties.description,
         displayName = properties.displayName,
         resourceId = properties.resourceDetails.id,
         resourceName = extract(@".*/virtual[M,m]achines/(.*)/provider.*", 1, id),
         resourceSource = properties.resourceDetails.source,
         category = properties.category,
         severity = properties.status.severity,
         code = properties.status.code,
         timeGenerated = properties.timeGenerated,
         remediation = properties.remediation,
         impact = properties.impact,
         vulnId = properties.id
| project-away properties
"@

if (-Not (Test-Path -Path $ExportPath)) {
    Write-Error ("Path {0} not found" -f $ExportPath) -ErrorAction Stop
}

$ExportFullPath = Join-Path -Path $ExportPath -ChildPath $ExportFileName
if ((Test-Path $ExportFullPath) -and -not $Force) {
    Write-Error ("File {0} already exists. Use '-Force' to overwrite" -f $ExportFullPath)
    Exit 1
}



do {
    # Create parameters for Search-AzGraph
    $queryParams = @{
        Query = $query
    }
    if ($result.SkipToken) {
        $queryParams = @{
            Query = $query
            SkipToken = $result.SkipToken
        }
    }
    if ($SubscriptionId) {
        $queryParams += @{
            Subscription = $SubscriptionId
        }
    } else {
        $queryParams += @{
            UseTenantScope = $true
        }
    }
    
    # Create parameters for Export-Csv
    $csvParams = @{
        Path = $ExportFullPath
        Delimiter = $Delimiter
    }
    if (-Not $firstRun) {
        $csvParams += @{ Append = $true }
    }

    # Retrieve and export results
    $result = Search-AzGraph @queryParams
    $result | Select-Object -ExcludeProperty id | Export-Csv @csvParams

    # Make sure all the next results will be appended
    $firstRun = $false

    # Show that we are busy
    if (-Not ($DebugPreference -eq "continue" -or $VerbosePreference -eq "continue")){
        Write-Host "." -NoNewline
    }
} while ($result.SkipToken)
