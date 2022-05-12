Param(
    [string]
    $applicationPrefix,

    [string]
    $spnDisplayName
)

# Get info messages out
$InformationPreference = "continue"

# Get applications
Try {
    $uri = ("https://graph.microsoft.com/v1.0/applications?`$filter=startswith(displayName, '{0}')" -f $applicationPrefix)
    $headers = @{"Authorization" = ("Bearer {0}" -f (Get-AzAccessToken -ResourceTypeName MSGraph).Token); "Content-Type" = "application/json"}
    $apps = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).Value
} catch {
    $_.Exception | Format-List *
    throw $_.Exception
}

# Set app owner
$spnId = (Get-AzADServicePrincipal -DisplayName $spnDisplayName).id
If (-Not $spnId) {Throw ("No Service Principal was found with the displayname {0}" -f $spnDisplayName)}

# Loop through all the found applications and attempt to add the spn id to the owners
foreach ($app in $apps) {
    Try {
        # Get current owners
        $uri = ("https://graph.microsoft.com/v1.0/applications/{0}/owners" -f $app.id)
        $headers = @{"Authorization" = ("Bearer {0}" -f (Get-AzAccessToken -ResourceTypeName MSGraph).Token); "Content-Type" = "application/json"}
        $appOwners = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).Value
        if ($spnId -in $appOwners.id){
            Write-Host ("Service principal '{0}' with objectId '{1}' already is owner on application '{2}'" -f $spnDisplayName, $spnId, $app.displayName)
            continue
        }
        # Set owner
        $uri = ("https://graph.microsoft.com/v1.0/applications/{0}/owners/`$ref" -f $app.id)
        $body = @{'@odata.id' = ("https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $spnId)} | convertto-json -compress
        $headers = @{"Authorization" = ("Bearer {0}" -f (Get-AzAccessToken -ResourceTypeName MSGraph).Token); "Content-Type" = "application/json"}
        Invoke-RestMethod -method Post -uri $uri -headers $headers -body $body
        Write-Host ("Add objectId '{0}' from service principal '{1}' to the application '{2}'" -f $spnId, $spnDisplayName, $app.displayName)
    } catch {
        if ($_.Exception.Response -match "StatusCode: 403, ReasonPhrase: 'Forbidden'") {
            Write-Error ("Access to application with name '{0}' was denied!" -f $app.displayName)
        } else {
            throw $_.Exception
        }
    }
}
