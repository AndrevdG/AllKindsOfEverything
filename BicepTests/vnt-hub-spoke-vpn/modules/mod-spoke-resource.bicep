targetScope = 'subscription'

param spoke object

// only used for deployment names
param postfix string = utcNow()

var vm2deploy = contains(spoke, 'vm') ? spoke.vm : []

module vm 'mod-vm-linux.bicep' = [for vm in vm2deploy : {
  name: '${vm.baseName}-${postfix}'
  scope: resourceGroup(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name)
  params: {
    config: vm
    vnetId: resourceId(contains(spoke, 'subscriptionId') ? spoke.subscriptionId : subscription().subscriptionId, spoke.rsg.name, 'Microsoft.Network/virtualNetworks', spoke.vnet.name)
    location: spoke.rsg.location
  }
}]
