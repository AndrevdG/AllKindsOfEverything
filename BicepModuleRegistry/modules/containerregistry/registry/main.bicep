targetScope = 'resourceGroup'

@description('The name of the container registry. Mandatory.')
param name string

@description('The location of the container registry. Defaults to the location of the resource group.')
param location string = resourceGroup().location

@description('The SKU of the container registry. Defaults to Basic.')
param sku string = 'Basic'

@description('Enable admin user. Defaults to false.')
param adminUserEnabled bool = false

@description('Enable anonymous pull. Defaults to false. Only available for SKU higher than Basic.')
param anonymousPullEnabled bool = false

@description('The public network access of the container registry. Defaults to Enabled. Only available for SKU Premium.')
param publicNetworkAccess bool = true

@description('The tags of the container registry. Defaults to {}.')
param tags object = {}

// deploy a simple container registry
resource registry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name 
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: sku != 'Basic' ? anonymousPullEnabled : false
    publicNetworkAccess: sku == 'Premium' && !publicNetworkAccess ? 'Disabled' : 'Enabled'
  }
}

output registryId string = registry.id
