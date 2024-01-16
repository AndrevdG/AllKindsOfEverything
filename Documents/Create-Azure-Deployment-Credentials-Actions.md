In order to deploy to Azure using Github Actions, we need to create deployment credentials.

Two ways are possible:
- Using a Service Principal - This allows for authentication using a app secret. During the lifetime of the secret (max 2 years) the secret does not (have to) change
- Using OpenId Connect - This is more complex but allows for using short lived tokens

While writing this I opted for the OpenId Connect way:

```PowerShell
# Create an Azure AD Application
$id = (az ad app create --display-name myApp) | ConvertFrom-Json

# Create a service principal
$spn = (az ad sp create --id $id.appId) | ConvertFrom-Json

# Create a role assignment to grant access to the spn
# For ease of use, I assigned the spn permission to the subscription level
$subscriptionId = "xxxxx"
az role assignment create --role contributor --scope /subscriptions/$subscriptionId --assignee-object-id  $spn.id --assignee-principal-type ServicePrincipal

# Create a new federated identity
$uri = ("https://graph.microsoft.com/beta/applications/{0}/federatedIdentityCredentials" -f $id.Id)

$credName = "AValueToReference"
$ghOrg = "GHOrganization"
$ghRepo = "GHRepository"
$ghBranch = "main"
$description = "description"

$body = @{
    name = $credName
    issuer = "https://token.actions.githubusercontent.com"
    subject = ("repo:{0}/{1}:ref:refs/heads/{2}" -f $ghOrg, $ghRepo, $ghBranch)
    description = $description
    audiences = @(
        "api://AzureADTokenExchange"
    )
} | ConvertTo-Json -Compress

az rest --method POST --uri $uri --body $body.replace('"', '\"') --headers content-type=application/json

```

In order to use these credentials you need to provide them in the workflow or can be stored as Github secrets. Using the latter seems the best approach. To add them:

- Go to the Github repository
- Go to 'settings' and 'secrets and variables' and open 'actions'
- Add the three secrets (you can obviously change the names if required):
   - **AZURE_CLIENT_ID**: This is the application id for the application created earlier
   - **AZURE_TENANT_ID**: The id for the tenant
   - **AZURE_SUBSCRIPTION_ID**: And the id for the subscription

In order to deploy resources to Azure you need to add to things to your workflow:

- Add permissions for the token
- Use the azure/login action to obtain an access token

For instance:

```YAML
name: Run Azure Login with OIDC
on: [push]

permissions:
      id-token: write
      contents: read
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: 'Az CLI login'
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: 'Run az commands'
        run: |
          az account show
          az group list
```


Reference: 
- https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions?tabs=openid
- https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure

