param name string
param vnets2link array
param linkOnly bool = false

resource dns 'Microsoft.Network/privateDnsZones@2020-06-01' = if (!linkOnly) {
  name: name
  location: 'global'
}

resource linkedvnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for vnet in vnets2link : {
  name: '${dns.name}/${uniqueString(vnet)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet
    }
    registrationEnabled: false
  }
}]
