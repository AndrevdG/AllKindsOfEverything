# Add service principal with a specific display name as owner to one or more applications
#
# Example:
# Add-SpnToApplicationOwner.ps1 -applicationPrefix 'svc-ccc' -spnDisplayName 'fna-mns-ago-d-01'

Param(
    [string]
    $spnDisplayName,

    [string]
    $appRoleToGrant
)

# MS Graph application ID is globally the same
$graphId = (Get-AzADServicePrincipal -ApplicationId '00000003-0000-0000-c000-000000000000').Id
# Get MS Graph Service principal and obtain the role id for the appRoleToGrant
$uri = ("https://graph.microsoft.com/v1.0/serviceprincipals/{0}" -f $graphId)
$headers = @{"Authorization" = ("Bearer {0}" -f (Get-AzAccessToken -ResourceTypeName MSGraph).Token); "Content-Type" = "application/json"}
$appRoleId = ((Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).appRoles | Where-Object {$_.value -eq $appRoleToGrant}).id
if (-Not $appRoleId){
    Throw ("Application role with name '{0}' not found on MS Graph service principal" -f $appRoleToGrant)
} else {
    Write-Host ("Application role '{0}' has role id {1}" -f $appRoleToGrant, $appRoleId)
}

# Get service principal id
$spnId = (Get-AzADServicePrincipal -DisplayName $spnDisplayName).id
if (-Not $spnId){
    Throw ("Service principal with name '{0}' not found on MS Graph service principal" -f $spnDisplayName)
}

# Check if permission was set already
$uri = ("https://graph.microsoft.com/v1.0/serviceprincipals/{0}/appRoleAssignments" -f $spnId)
$headers = @{"Authorization" = ("Bearer {0}" -f (Get-AzAccessToken -ResourceTypeName MSGraph).Token); "Content-Type" = "application/json"}
$grantedAppRoles = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).value

if ($appRoleId -in $grantedAppRoles.appRoleId) {
    Write-Host ("Application Role '{0}' is already granted on service principal '{1}' with objectId '{2}'" -f $appRoleToGrant, $spnDisplayName, $spnId)
} else {
    # Set Permission
    $uri = ("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/appRoleAssignments" -f $spnId)
    $body= "{'principalId':'$spnId','resourceId':'$graphId','appRoleId':'$appRoleId'}"
    $headers = @{"Authorization" = ("Bearer {0}" -f (Get-AzAccessToken -ResourceTypeName MSGraph).Token); "Content-Type" = "application/json"}
    [Void](Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body)
    Write-Host ("Application Role '{0}' has been granted on service principal '{1}' with objectId '{2}'" -f $appRoleToGrant, $spnDisplayName, $spnId)
}