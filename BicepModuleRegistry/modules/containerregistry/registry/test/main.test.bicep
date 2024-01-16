targetScope = 'resourceGroup'

param name string = deployment().name
param location string = resourceGroup().location
param tags object = {
  environment: 'dev'
  location: location
}

module simpleTest '../main.bicep' = {
  name: '${name}-simpleTest'
  params: {
    name: 'testregistry'
    location: location
    tags: tags
    sku: 'basic'
  }
}
