targetScope = 'subscription'

param config object

// only used for deployment names
param postfix string = utcNow()

var vnetConfig = union(config.spoke, array(config.hub))

// Note: this variable only takes the first item from every vnet.addressSpace. In my experience,
// vnets rarely get assigned two (or more) address spaces, but it is a valid configuration. However, dealing with that
// from within bicep, while (sort of) possible, is a pain in the behind. So we will leave that out in here.
var spokeAddressRanges = [for spoke in config.spoke: {
  name: spoke.vnet.name
  range: spoke.vnet.addressSpace[0]
}]

var hubSubscriptionId = contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId

// Create resource groups
module rsg 'modules/mod-rsg.bicep' = [for item in vnetConfig: {
  name: '${item.rsg.name}-${postfix}'
  scope: subscription(contains(item, 'subscriptionId') ? item.SubscriptionId : subscription().subscriptionId)
  params: {
    name: item.rsg.name
    location: item.rsg.location
    resourceGroupAssignments: config.general.resourceGroupAssignments
  }
}]

// Create vnets
module vnets 'modules/mod-vnet.bicep' = [for item in vnetConfig: {
  scope: resourceGroup(contains(item, 'subscriptionId') ? item.subscriptionId : subscription().subscriptionId, item.rsg.name)
  dependsOn: [
    rsg
  ]
  name: '${item.vnet.name}-${postfix}'
  params:{
    vnetName: item.vnet.name
    location: item.rsg.location
    addressPrefixes: item.vnet.addressSpace
    subnets: item.vnet.subnets
    //nsgId: item.vnet.name == config.hub.vnet.name ? nsg.outputs.nsgId : ''
  }
}]

// Create peerings on the hub
module hubPeerings 'modules/mod-vnet-hub-peering.bicep' = {
  scope: resourceGroup(contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId, config.hub.rsg.name)
  name: 'hubPeering-${postfix}'
  dependsOn: [
    vnets
  ]
  params: {
    hub: config.hub
    spoke: config.spoke
  }
}

// Create peerings on the spoke(s)
module spokePeerings 'modules/mod-vnet-spoke-peering.bicep' = [for item in config.spoke: {
  scope: resourceGroup(contains(item, 'subscriptionId') ? item.subscriptionId : subscription().subscriptionId, item.rsg.name)
  name: '${item.vnet.name}-peering-${postfix}'
  dependsOn: [
    vnets
  ]
  params:{
    hub: config.hub
    vnetName: item.vnet.name
  }
}]

// Deploy Ubuntu VM to use as NAT/Router
module vm 'modules/mod-vm-linux.bicep' = [for vm in config.hub.vm : {
  name: '${vm.baseName}-${postfix}'
  scope: resourceGroup(hubSubscriptionId, config.hub.rsg.name)
  dependsOn: vnets
  params: {
    config: vm
    vnetId: resourceId(contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId, config.hub.rsg.name, 'Microsoft.Network/virtualNetworks', config.hub.vnet.name)
    location: config.hub.rsg.location
    vmCustomDataBase64: startsWith(vm.baseName, 'fw-') ? loadFileAsBase64('configs/cloud-init-fw.yml') : loadFileAsBase64('configs/cloud-init-vm.yml')
  }
}]

module privateDns 'modules/mod-private-dns.bicep' = [for dns in config.hub.dns : {
  name: '${replace(dns,'.','-')}-${postfix}'
  scope: resourceGroup(hubSubscriptionId, config.hub.rsg.name)
  dependsOn: [
    hubPeerings
    spokePeerings
  ]
  params: {
    name: dns
    vnets2link: [for (item,i) in vnetConfig: vnets[i].outputs.vnetId]
  }
}]

// Create route tables for every subnet, unless an exception is configured
module routetables 'modules/mod-routetable.bicep' = [for i in range(0, length(vnetConfig)) : {
  name: 'routetables-${vnetConfig[i].vnet.name}-${postfix}'
  dependsOn:[
    vm
  ]
  scope: resourceGroup(contains(vnetConfig[i], 'subscriptionId') ? vnetConfig[i].subscriptionId : subscription().subscriptionId, vnetConfig[i].rsg.name)
  params:{
    vnetName: vnetConfig[i].vnet.name
    location: vnetConfig[i].rsg.location
    subnets: vnetConfig[i].vnet.subnets
    fwIp: vm[0].outputs.vmIp[0]
    spokeAddressRanges: spokeAddressRanges
  }
}]

// Create VPN Gateway in hub
module vgw 'modules/mod-vgw.bicep' = if(contains(config.hub, 'vgw')) {
  scope: resourceGroup(hubSubscriptionId, config.hub.rsg.name)
  name: '${config.hub.vgw.name}-${postfix}'
  dependsOn: [
    routetables
  ]
  params: {
    name: config.hub.vgw.name
    location: config.hub.rsg.location
    tier: config.hub.vgw.tier
    vnetId: resourceId(hubSubscriptionId, config.hub.rsg.name, 'Microsoft.Network/virtualNetworks', config.hub.vnet.name)
  }
}

// Create resources in spokes as defined in config
module spokeResource 'modules/mod-spoke-resource.bicep' = [for (spoke, i) in config.spoke : {
  name: 'spokeResources-${i}-${postfix}'
  dependsOn: [
    vgw
  ]
  params: {
    spoke: spoke
    hub: config.hub
  }
}]


