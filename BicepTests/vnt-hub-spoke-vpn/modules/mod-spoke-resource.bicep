targetScope = 'subscription'

param spoke object
param hub object

// only used for deployment names
param postfix string = utcNow()

var vm2deploy = contains(spoke, 'vm') ? spoke.vm : []
var sta2deploy = contains(spoke, 'sta') ? spoke.sta : []

module vm 'mod-vm-linux.bicep' = [for vm in vm2deploy : {
  name: '${vm.baseName}-${postfix}'
  scope: resourceGroup(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name)
  params: {
    config: vm
    vnetId: resourceId(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name, 'Microsoft.Network/virtualNetworks', spoke.vnet.name)
    location: spoke.rsg.location
    vmCustomDataBase64: loadFileAsBase64('../configs/cloud-init-vm.yml')
  }
}]

module sta 'mod-sta-with-pep.bicep' = [for sta in sta2deploy : {
  name: '${sta.name}-${postfix}'
  scope: resourceGroup(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name)
  params: {
    name: sta.name
    subnet: sta.subnet
    blobContainers: sta.containers
    location: spoke.rsg.location
    vnetId: resourceId(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name, 'Microsoft.Network/virtualNetworks', spoke.vnet.name)
    dnsSubscriptionId: contains(hub, 'subscriptionId') ? hub.subscriptionId : subscription().subscriptionId
    dnsResourceGroup: hub.rsg.name
  }
}]
