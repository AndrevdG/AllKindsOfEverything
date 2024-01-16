param adminUserName string

@secure()
param adminPassword string
param vmSize string
param location string = resourceGroup().location
param nicName string
param vmName string
param diskNameOs string
param diskType string = 'Standard_LRS'
param createPip bool = true
param pipName string
param createSMId bool = true
param windowsOSVersion string
param subnetRef string

var _imageInfo = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsOSVersion
  version: 'latest'
}

resource pIP 'Microsoft.Network/publicIPAddresses@2021-03-01' = if (createPip) {
  name: pipName
  sku: {
    name: 'Basic'
  }
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nInter 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          publicIPAddress: createPip ? { 
            id: pIP.id 
          } : null
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  identity: createSMId ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    licenseType: 'Windows_Client'
    storageProfile: {
      imageReference: _imageInfo
      osDisk: {
        name: diskNameOs
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nInter.id
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

resource shutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'W. Europe Standard Time'
    dailyRecurrence: {
      time: '23:30'
    }
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
      webhookUrl: ''
    }
    targetResourceId: vm.id
  }
}

output vmName string = vm.name
