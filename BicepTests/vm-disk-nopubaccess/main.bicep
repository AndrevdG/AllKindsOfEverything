targetScope = 'resourceGroup'

param vnetName string
@secure()
param vmPassword string
param location string = 'westeurope'

// only used for deployment names
param postfix string = utcNow()

var vmConfig = {
  vmName: 'vm-tst-disk-nopub-be02'
  pipName: 'vm-tst-disk-nopub-be02-pip'
  nicName: 'vm-tst-disk-nopub-be02-nic'
  diskNameOs: 'vm-tst-disk-nopub-be02-osd'
  diskType: 'Standard_LRS'
  size: 'Standard_B1s'
  adminUserName: 'vm-admin'
  subnet: 'backend'
  imageReference: {
      publisher: 'canonical'
      offer: '0001-com-ubuntu-server-focal'
      sku: '20_04-lts-gen2'
      version: 'latest'
  }
  createPip: false
  createPipStatic: false
  enableIPForwarding: false
  staticIp: false
}


resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetName
}

module vm 'modules/mod-vm-linux.bicep' = {
  name: '${vmConfig.vmName}-${postfix}'
  params: {
    config: vmConfig
    vmPassword: vmPassword
    vnetId: vnet.id
    location: location
  }
}
