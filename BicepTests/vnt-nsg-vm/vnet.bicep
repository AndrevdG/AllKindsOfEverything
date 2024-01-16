param vnetName string
param location string = resourceGroup().location
param addressPrefixes array = [
  '192.168.20.0/24'
]
param subnets array = [
  {
    name: 'default'
    addressPrefix: '192.168.20.0/24'
  }
]
param nsgId string = ''


resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for sn in subnets: {
      name: sn.name
      properties: {
        addressPrefix: sn.addressPrefix
        networkSecurityGroup: !empty(nsgId) ? {
          id: nsgId
        } : null
        privateEndpointNetworkPolicies: sn.privateEndpointNetworkPolicies
      }
    }]
  }
}

output vnetId string = vnet.id
