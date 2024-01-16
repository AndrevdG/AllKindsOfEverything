param hub object
param spoke array

// Create peerings on the hub vnet
resource hubpeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = [for item in spoke: {
  name: '${hub.vnet.name}/${item.vnet.name}-peering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(contains(item, 'subscriptionId') ? item.subscriptionId : subscription().subscriptionId, item.rsg.name,'Microsoft.Network/virtualNetworks',item.vnet.name)
    }
    remoteAddressSpace: {
      addressPrefixes: item.vnet.addressSpace
    }
  }
}]
