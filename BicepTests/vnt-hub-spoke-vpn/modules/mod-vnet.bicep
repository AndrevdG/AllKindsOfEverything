param vnetName string
param location string
param addressPrefixes array
param subnets array
//param nsgId string = ''

// only used for deployment names
param postfix string = utcNow()

// create default nsg for each virtual network

module nsg 'mod-nsg.bicep' = {
  name: 'nsg-${vnetName}-${postfix}'
  params: {
    nsgName: '${vnetName}-nsg'
    location: location
  }
}

// create non-default nsg if required
module nsgSpecific 'mod-nsg.bicep' = [ for subnet in subnets : if (contains(subnet, 'nsg')) {
  name: 'sn-${subnet.name}-${postfix}-nsg'
  params: {
    nsgName: 'nsg-sn-${subnet.name}'
    location: location
    allowedIps: contains(subnet.nsg, 'allowedIps') && !empty(subnet.nsg.allowedIps) ? subnet.nsg.allowedIps : []
    allowInternetForwarding: contains(subnet.nsg, 'allowInternetForwarding') && subnet.nsg.allowInternetForwarding == true ? true : false
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for (subnet, i) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.range
        networkSecurityGroup: (contains(subnet, 'noNetworkSecurityGroup') && subnet.noNetworkSecurityGroup == true) ? null : {
          id: contains(subnet, 'nsg') ? nsgSpecific[i].outputs.nsgId : nsg.outputs.nsgId
        }
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : null
      }
    }]
  }
}

output vnetId string = vnet.id
