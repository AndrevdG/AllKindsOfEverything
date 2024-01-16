###### Does not appear to fully work yet
###### New credential is created but without displayName and wrong enddate??
######

function New-ApplicationSecretGraph {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
    Param(
        [object]$eventRow
    )

    $spn = _parseSpn -objectName $eventRow.objectName
    
    if ([int]$env:spnValidityPeriodInDays) { $validityPeriodDays = $env:spnValidityPeriodInDays } else { $validityPeriodDays = 365 }

    # Create a new secret for an application and convert the secretText to securestring
    Write-Information ("Creating a new secret for spn {0} via MS Graph" -f $spn.name)

    # Managed id needs AD Reader role to be able to read applications. Can maybe be restricted with a custom role (applications only)
    # Or through msgraph permissions and revising this to use ms graph to obtain the app id
    $appId = (Get-AzADApplication -DisplayName $spn.Name).Id
    $uri = ("https://graph.microsoft.com/v1.0/applications/{0}/addPassword" -f $appId)
    $headers = @{"Authorization" = ("Bearer {0}" -f (Get-AzAccessToken -ResourceTypeName MSGraph).Token); "Content-Type" = "application/json"}
    $body= "{'displayName':'Test-With-msGraph','endDateTime':'$((Get-Date).AddDays($validityPeriodDays))','startDateTime':'$(Get-Date)'}"

    $secret = Invoke-RestMethod -Method Post -Uri $uri -Body $body -Headers $headers | Select-Object -Property DisplayName, EndDateTime, StartDateTime, `
                @{ Name = 'SecureSecretText';  Expression = {ConvertTo-SecureString -String $_.SecretText -AsPlainText -Force}}

    return $secret
}