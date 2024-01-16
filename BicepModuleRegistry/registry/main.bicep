targetScope = 'subscription'

param postfix string = utcNow()

// load config from json file
var config = loadJsonContent('registry.json')
var acr = config.acr
var resourceGroup = config.resourceGroup

// Create a resource group
resource rsg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroup.name
  location: resourceGroup.location
}

// Create an Azure Container Registry
module registry 'br/amacr:bicep/modules/containerregistry/registry:v0.1' = {
  scope: rsg
  name: 'deploy-${acr.name}-${postfix}'
  params: {
    name: acr.name
    location: resourceGroup.location
    sku: acr.sku
    adminUserEnabled: acr.adminUserEnabled
  }
}
