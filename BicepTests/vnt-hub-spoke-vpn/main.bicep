targetScope = 'subscription'

param projectName string 

// only used for deployment names
param postfix string = utcNow()

var config = json(replace(loadTextContent('configs/config.json'), '__projectname__', projectName))
var vnetConfig = union(config.spoke, array(config.hub))

// Note: this variable only takes the first item from every vnet.addressSpace. In my experience,
// vnets rarely get assigned two (or more) address spaces, but it is a valid configuration. However, dealing with that
// from within bicep, while (sort of) possible, is a pain in the behind. So we will leave that out in here.
var spokeAddressRanges = [for spoke in config.spoke: {
  name: spoke.vnet.name
  range: spoke.vnet.addressSpace[0]
}]

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

module fw 'modules/mod-vm-linux.bicep' = [for vm in config.hub.vm : {
  name: '${vm.baseName}-${postfix}'
  scope: resourceGroup(contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId, config.hub.rsg.name)
  dependsOn: vnets
  params: {
    config: vm
    vnetId: resourceId(contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId, config.hub.rsg.name, 'Microsoft.Network/virtualNetworks', config.hub.vnet.name)
    location: config.hub.rsg.location
    vmCustomDataBase64: loadFileAsBase64('configs/cloud-init-fw.yml')
  }
}]

module routetables 'modules/mod-routetable.bicep' = [for i in range(0, length(vnetConfig)) : {
  name: 'routetables-${vnetConfig[i].vnet.name}-${postfix}'
  dependsOn:[
    fw
  ]
  scope: resourceGroup(contains(vnetConfig[i], 'subscriptionId') ? vnetConfig[i].subscriptionId : subscription().subscriptionId, vnetConfig[i].rsg.name)
  params:{
    vnetName: vnetConfig[i].vnet.name
    location: vnetConfig[i].rsg.location
    subnets: vnetConfig[i].vnet.subnets
    fwIp: fw[0].outputs.vmIp[0]
    spokeAddressRanges: spokeAddressRanges
  }
}]

module spokeResource 'modules/mod-spoke-resource.bicep' = [for (spoke, i) in config.spoke : {
  name: 'spokeResources-${i}-${postfix}'
  dependsOn: [
    routetables
  ]
  params: {
    spoke: spoke
  }
}]


