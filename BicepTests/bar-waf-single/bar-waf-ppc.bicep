param wafName string
@secure()
param adminPassword string
// We use multiple ip addresses for services, but it seems we cannot preapply them
// the WAF will set them when assigned from the interface
// (and remove preassigned addresses)
param ipAddresses array

param bootDiagnosticsStaUri string  // 'https://<storageaccount>.blob.core.windows.net/'
param subnetId string // '/subscriptions/<id>/resourceGroups/<RsgName>/providers/Microsoft.Network/virtualNetworks/<VnetName>/subnets/<subnetName>'
param nsgId string // '/subscriptions/<id>/resourceGroups/<RsgName>/providers/Microsoft.Network/networkSecurityGroups/<nsgName>'

//Optional
param location string = resourceGroup().location
param adminUsername string = 'adm_waf'


resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nic-${wafName}'
  location: location
  properties: {
    ipConfigurations: [for (ip,i) in ipAddresses: {
      name: 'ipconfig${i}'
      properties: {
        privateIPAddress: ip
        privateIPAllocationMethod: 'Static'
        subnet: {
          id: subnetId
        }
        primary: i==0 ? true : false
      }
    }]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

resource waf 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: wafName
  location: location
  zones: [
    '1'
  ]
  plan: {
    name: 'byol'
    publisher: 'barracudanetworks'
    product: 'waf'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'barracudanetworks'
        offer: 'waf'
        sku: 'byol'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        osType: 'Linux'
        name: 'osd-${wafName}'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 50
      }
      dataDisks: []
    }
    osProfile: {
      computerName: wafName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
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
        storageUri: bootDiagnosticsStaUri
      }
    }
  }
}
