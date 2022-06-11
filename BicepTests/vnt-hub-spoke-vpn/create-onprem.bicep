targetScope = 'subscription'

param config object

// only used for deployment names
param postfix string = utcNow()

var onpremSubscriptionId = contains(config.onprem, 'subscriptionId') ? config.onprem.SubscriptionId : subscription().subscriptionId
var hubSubscriptionId = contains(config.hub, 'subscriptionId') ? config.hub.subscriptionId : subscription().subscriptionId

// Create resource groups
module rsg 'modules/mod-rsg.bicep' = {
  name: '${config.onprem.rsg.name}-${postfix}'
  scope: subscription(onpremSubscriptionId)
  params: {
    name: config.onprem.rsg.name
    location: config.onprem.rsg.location
    resourceGroupAssignments: config.general.resourceGroupAssignments
  }
}

// Create vnets
module vnet 'modules/mod-vnet.bicep' = {
  scope: resourceGroup(onpremSubscriptionId, config.onprem.rsg.name)
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
  scope: resourceGroup(onpremSubscriptionId, config.onprem.rsg.name)
  dependsOn:[
    vnet
  ]
  name: '${config.onprem.vgw.name}-${postfix}'
  params: {
    name: config.onprem.vgw.name
    location: config.onprem.rsg.location
    tier: config.onprem.vgw.tier
    vnetId: resourceId(onpremSubscriptionId, config.onprem.rsg.name, 'Microsoft.Network/virtualNetworks', config.onprem.vnet.name)
  }
}

// Deploy Ubuntu VM as onprem resource
module vm 'modules/mod-vm-linux.bicep' = [for vm in config.onprem.vm : {
  name: '${vm.baseName}-${postfix}'
  scope: resourceGroup(onpremSubscriptionId, config.onprem.rsg.name)
  dependsOn: [
    vnet
  ]
  params: {
    config: vm
    vnetId: resourceId(onpremSubscriptionId, config.onprem.rsg.name, 'Microsoft.Network/virtualNetworks', config.onprem.vnet.name)
    location: config.onprem.rsg.location
    vmCustomDataBase64: loadFileAsBase64('configs/cloud-init-vm.yml')
  }
}]

// Link to the privatelink.blob.windows.net - Normally you would use a dns relay in in azure from your onprem dns
module privateDns 'modules/mod-private-dns.bicep' = [for dns in config.hub.dns : {
  name: '${replace(dns,'.','-')}-link-${postfix}'
  scope: resourceGroup(hubSubscriptionId, config.hub.rsg.name)
  params: {
    name: dns
    vnets2link: [
      vnet.outputs.vnetId
    ]
    linkOnly: true
  }
}]

