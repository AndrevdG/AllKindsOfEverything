targetScope = 'subscription'

param config object

// only used for deployment names
param postfix string = utcNow()

// Create resource groups
module rsg 'modules/mod-rsg.bicep' = {
  name: '${config.onprem.rsg.name}-${postfix}'
  scope: subscription(contains(config.onprem, 'subscriptionId') ? config.onprem.SubscriptionId : subscription().subscriptionId)
  params: {
    name: config.onprem.rsg.name
    location: config.onprem.rsg.location
    resourceGroupAssignments: config.general.resourceGroupAssignments
  }
}

// Create vnets
module vnet 'modules/mod-vnet.bicep' = {
  scope: resourceGroup(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name)
  dependsOn: [
    rsg
  ]
  name: '${config.onprem.vnet.name}-${postfix}'
  params:{
    vnetName: config.onprem.vnet.name
    location: config.onprem.rsg.location
    addressPrefixes: config.onprem.vnet.addressSpace
    subnets: config.onprem.vnet.subnets
    //nsgId: item.vnet.name == config.hub.vnet.name ? nsg.outputs.nsgId : ''
  }
}

// Create VPN Gateway onprem
module vgw 'modules/mod-vgw.bicep' = if(contains(config.onprem, 'vgw')) {
  scope: resourceGroup(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name)
  dependsOn:[
    vnet
  ]
  name: '${config.onprem.vgw.name}-${postfix}'
  params: {
    name: config.onprem.vgw.name
    location: config.onprem.rsg.location
    tier: config.onprem.vgw.tier
    vnetId: resourceId(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name, 'Microsoft.Network/virtualNetworks', config.onprem.vnet.name)
  }
}

// Deploy Ubuntu VM as onprem resource
module fw 'modules/mod-vm-linux.bicep' = [for vm in config.onprem.vm : {
  name: '${vm.baseName}-${postfix}'
  scope: resourceGroup(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name)
  dependsOn: [
    vnet
  ]
  params: {
    config: vm
    vnetId: resourceId(contains(config.onprem, 'subscriptionId') ? config.onprem.subscriptionId : subscription().subscriptionId, config.onprem.rsg.name, 'Microsoft.Network/virtualNetworks', config.onprem.vnet.name)
    location: config.onprem.rsg.location
  }
}]

output vgwPublicIpOnprem string = vgw.outputs.vgwPublicIp
