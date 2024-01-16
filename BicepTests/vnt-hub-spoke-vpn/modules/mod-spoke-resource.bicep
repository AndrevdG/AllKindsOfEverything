targetScope = 'subscription'

param spoke object
param hub object

// only used for deployment names
param postfix string = utcNow()

var vm2deploy = contains(spoke, 'vm') ? spoke.vm : []
var sta2deploy = contains(spoke, 'sta') ? spoke.sta : []
var kv2deploy = contains(spoke, 'kv') ? spoke.kv : []

var scope = resourceGroup(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name)
var vnetId = resourceId(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name, 'Microsoft.Network/virtualNetworks', spoke.vnet.name)
var hubSubscriptionId = contains(hub, 'subscriptionId') ? hub.subscriptionId : subscription().subscriptionId


module vm 'mod-vm-linux.bicep' = [for vm in vm2deploy : {
  name: '${vm.baseName}-${postfix}'
  scope: scope
  params: {
    config: vm
    vnetId: vnetId
    location: spoke.rsg.location
    vmCustomDataBase64: loadFileAsBase64('../configs/cloud-init-vm.yml')
  }
}]

module sta 'mod-sta-with-pep.bicep' = [for sta in sta2deploy : {
  name: '${sta.name}-${postfix}'
  scope: scope
  params: {
    name: sta.name
    subnet: sta.subnet
    blobContainers: sta.containers
    location: spoke.rsg.location
    vnetId: vnetId
    roles: contains(sta, 'roles') ? sta.roles : []
    dnsSubscriptionId: hubSubscriptionId
    dnsResourceGroup: hub.rsg.name
  }
}]

module kv 'mod-kv-with-pep.bicep'  = [for kv in kv2deploy : {
  name: '${kv.name}-${postfix}'
  scope: scope
  params: {
    name: kv.name
    location: spoke.rsg.location
    subnet: kv.subnet
    vnetId: vnetId
    roles: contains(kv, 'roles') ? kv.roles : []
    dnsSubscriptionId: hubSubscriptionId
    dnsResourceGroup: hub.rsg.name
  }
}]
