param config object
param vnetId string
param vmCustomDataBase64 string = ''

// only used for deployment names
param postFix string = utcNow()
param location string = resourceGroup().location

var vmConfig = [for i in range (1, contains(config, 'count') ? config.count : 1) : {
  adminUserName: contains(config, 'adminUserName') && !empty(config.adminUserName) ? config.adminUserName : 'admin_user'
  // defaults to a bogus ssh key: I generated a keypair, used the public and removed it. Use at your own peril!
  adminSshKey: contains(config, 'adminSshKey') && !empty(config.adminSshKey) ? config.adminSshKey : 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPmLLlojkjTSc9/aRjkrZXVh/6U+iSX6LgIrXaeue53OZIb6NV9ZQZ3HhEkbU+TIrGTajl1TnMdCpkgYjhsccePBTnNQvdC7frikV+0taj7UPTmlhTBqME9fpndvJyIzQu8zJye4lgBWSJBo8DMlDf/A4CKDUtDlf5npNl9BhyBCKYNrQtbTiCpaBn4APC67PG0cV/RIJwvUEglpHHuT2B0PauUVev5PkTiAkeUEXEKFOSc8Ojx02n1xfFMwjdyEGVeAMJFk/HwvoL9Gycq0JSN6q/F/tXO3MOF6Wd33RMVFotuaMpGJQxnRXLhPIIuDB0N1MIT0sE35CQiYBl3y+jtvkB6qx/8NkCp9iJekMnE4Z0tSYLKqrFepM/Fz/878jfoeQoeMBnf/4T1WyBdHJKDPuUD6or+idye2H4D6/TTUcwfw3Ph2gljW5INmEABkLxKZG2eR98Sfz9HjV6iQ/ogM7rf694OihSP25SsyHQF5naB0yNLeDXpDxcRumcp5cORikn8I6f5dbehk+nY+vKyABGOrtSVKgbeDLHH/Pe/SmxZqVlsrU9LohOt4c35UctMkP90EaDSbeIuDx2ssTNPLC9sEWjk9Un5xNsMUniKNizyG8/zyFI0lz4ySkLUvZBXe7LlqB5vC7XkDdvzZi1FFH/Nk5PtKoz7ps0Dl6Vqw== user@boguspc'
  vmSize: config.size
  location: contains(config, 'location') && !empty(config.location) ? config.location : location
  vmName: '${config.baseName}${padLeft(i,2,'0')}'
  pipName: '${config.baseName}${padLeft(i,2,'0')}-pip'
  nicName: '${config.baseName}${padLeft(i,2,'0')}-nic'
  diskNameOs: '${config.baseName}${padLeft(i,2,'0')}-osd'
  diskType: contains(config, 'diskType') ? config.diskType : 'Standard_LRS'
  subnetRef: '${vnetId}/subnets/${config.subnet}'
  imageReference: config.imageReference
  createPip: contains(config, 'createPip') && config.createPip == true ? true : false
  createPipStatic: contains(config, 'createPipStatic') && config.createPipStatic == true ? true : false
  createSMId: contains(config, 'createSMId') && config.createSMId == false ? false : true
  staticIp: contains(config, 'staticIp') && config.staticIp == true ? true : false
  enableIPForwarding: contains(config, 'enableIPForwarding') && config.enableIPForwarding == true ? true : false
}]


resource pip 'Microsoft.Network/publicIPAddresses@2021-03-01' = [ for vm in vmConfig : if (vm.createPip) {
  name: vm.pipName
  sku: {
    name: 'Basic'
  }
  location: vm.location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: vm.createPipStatic ? 'Static' : 'Dynamic'
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = [ for (vm, i) in vmConfig : {
  name: vm.nicName
  location: vm.location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vm.subnetRef
          }
          publicIPAddress: vm.createPip ? {
            id: pip[i].id
          } : null
        }
      }
    ]
    enableIPForwarding: vm.enableIPForwarding
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = [ for (vm, i) in vmConfig : {
  name: vm.vmName
  location: vm.location
  identity: vm.createSMId ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    hardwareProfile: {
      vmSize: vm.vmSize
    }
    osProfile: {
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: vm.adminSshKey
              path: '/home/${vm.adminUserName}/.ssh/authorized_keys'
            }
          ]
        }
      }
      computerName: vm.vmName
      adminUsername: vm.adminUserName
      customData: !empty(vmCustomDataBase64) ? vmCustomDataBase64 : null
    }
    storageProfile: {
      imageReference: vm.imageReference
      osDisk: {
        name: vm.diskNameOs
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vm.diskType
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]

resource aadLogin 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [ for (vm, i) in vmConfig : {
  parent: virtualMachine[i]
  name: 'aadLogin'
  location: vm.location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory.LinuxSSH'
    type: 'AADLoginForLinux'
    autoUpgradeMinorVersion: true
    typeHandlerVersion: '1.0'
    suppressFailures: true 
      // I have had occaisional failures deploying this extension.
      // However, usually it recovers after a while.
  }
}]

module setStaticIp 'util-nic-static-ip.bicep' = [ for (vm, i) in vmConfig : if (vm.staticIp) {
  name: 'staticIp-${nic[i].name}-${postFix}'
  dependsOn: [
    virtualMachine
  ]
  params: {
    name: nic[i].name
    location: nic[i].location
    ipconfigName: nic[i].properties.ipConfigurations[0].name
    ipAddress: nic[i].properties.ipConfigurations[0].properties.privateIPAddress
    subnetId: nic[i].properties.ipConfigurations[0].properties.subnet.id
    enableIPForwarding: vm.enableIPForwarding
    publicIpId: contains(nic[i].properties.ipConfigurations[0].properties, 'publicIPAddress') && !empty(nic[i].properties.ipConfigurations[0].properties.publicIPAddress) ? nic[i].properties.ipConfigurations[0].properties.publicIPAddress : {}
  }
}]

output vmName array = [ for (vm, i) in vmConfig : virtualMachine[i].name ]
// this only works consistently if only 1 ip is assigned to a nic. If you have a multiple ip scenario, you need to rethink this
output vmIp array = [ for (vm, i) in vmConfig : vm.staticIp ? setStaticIp[i].outputs.staticIP : nic[i].properties.ipConfigurations[0].properties.privateIPAddress]
