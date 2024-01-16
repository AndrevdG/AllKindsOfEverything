param config object
param vnetId string
@secure()
param vmPassword string

// only used for deployment names
param location string = resourceGroup().location

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: config.nicName
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetId}/subnets/${config.subnet}'
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: config.vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: config.size
    }
    osProfile: {
      computerName: config.vmName
      adminUsername: config.adminUserName
      adminPassword: vmPassword
    }
    storageProfile: {
      imageReference: config.imageReference
      osDisk: {
        name: config.diskNameOs
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: config.diskType
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// module osDisk 'util-disablepublic-managed-disk.bicep' = {
//   name: 'disablePublicAccess-${config.vmName}'
//   dependsOn: [
//     virtualMachine
//   ]
//   params: {
//     name: config.diskNameOs
//     location: location
//     sku: config.diskType
//   }
// }
