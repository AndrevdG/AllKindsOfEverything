targetScope = 'subscription'

param config object

// only used for deployment names
param postfix string = utcNow()


// Note: this variable only takes the first item from every vnet.addressSpace. In my experience,
// vnets rarely get assigned two (or more) address spaces, but it is a valid configuration. However, dealing with that
// from within bicep, while (sort of) possible, is a pain in the behind. So we will leave that out in here.
var spokeAddressRanges = [for spoke in config.spoke: spoke.vnet.addressSpace[0]]

// You may not want to do this in production, though the shared key is visible in the portal anyway...
var sharedKey = uniqueString(config.hub.vgw.name, onpremVgw.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0], config.onprem.vgw.name, hubVgw.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0])

// resource hubVgwPip 'Microsoft.Network/publicIPAddresses@2021-08-01' existing = {
//   name: '${config.hub.vgw.name}-pip'
//   scope: resourceGroup(contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId, config.hub.rsg.name)
// }

// resource onpremVgwPip 'Microsoft.Network/publicIPAddresses@2021-08-01' existing = {
//   name: '${config.onprem.vgw.name}-pip'
//   scope: resourceGroup(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name)
// }

resource hubVgw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' existing = {
  name: '${config.hub.vgw.name}'
  scope: resourceGroup(contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId, config.hub.rsg.name)
}

resource onpremVgw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' existing = {
  name: '${config.onprem.vgw.name}'
  scope: resourceGroup(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name)
}

module vpnHub 'modules/mod-s2s.bicep' = {
  name: 'con-hub-2-onprem-${postfix}'
  scope: resourceGroup(contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId, config.hub.rsg.name)
  params: {
    name: 'con-hub-2-onprem'
    location: config.hub.rsg.location
    dhGroup: config.general.vpnConnection.dhGroup
    ikeEncryption: config.general.vpnConnection.ikeEncryption
    ikeIntegrity: config.general.vpnConnection.ikeIntegrity
    ipsecEncryption: config.general.vpnConnection.ipsecEncryption
    ipsecIntegrity: config.general.vpnConnection.ipsecIntegrity
    pfsGroup: config.general.vpnConnection.pfsGroup
    lgwname: 'lgw-${config.onprem.vgw.name}'
    lgwAddresses: config.onprem.vnet.addressSpace
    lgwIpAddress: onpremVgw.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
    vgwName: config.hub.vgw.name
    sharedKey: sharedKey
  }
}

module vpnOnprem 'modules/mod-s2s.bicep' = {
  name: 'con-onprem-2-hub-${postfix}'
  scope: resourceGroup(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name)
  params: {
    name: 'con-onprem-2-hub'
    location: config.onprem.rsg.location
    dhGroup: config.general.vpnConnection.dhGroup
    ikeEncryption: config.general.vpnConnection.ikeEncryption
    ikeIntegrity: config.general.vpnConnection.ikeIntegrity
    ipsecEncryption: config.general.vpnConnection.ipsecEncryption
    ipsecIntegrity: config.general.vpnConnection.ipsecIntegrity
    pfsGroup: config.general.vpnConnection.pfsGroup
    lgwname: 'lgw-${config.hub.vgw.name}'
    lgwAddresses: union(config.hub.vnet.addressSpace, spokeAddressRanges)
    lgwIpAddress: hubVgw.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
    vgwName: config.onprem.vgw.name
    sharedKey: sharedKey
  }
}
