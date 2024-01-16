param hub object
param vnetName string

// Connect each spoke with the hub
resource spokepeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' =  {
  name: '${vnetName}/${hub.vnet.name}-peering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(contains(hub, 'subscriptionId') ? hub.subscriptionId : subscription().subscriptionId, hub.rsg.name,'Microsoft.Network/virtualNetworks', hub.vnet.name)
    }
    remoteAddressSpace: {
      addressPrefixes: hub.vnet.addressSpace
    }
  }
}
