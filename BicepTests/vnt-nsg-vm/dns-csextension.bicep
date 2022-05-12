param vmName string
param staName string
param cseName string = 'DnsScript'
param location string = resourceGroup().location
param cseForwarders string = '168.63.129.16'
param ConditionalForwarders array = [
  {
      Name: 'contoso.com'
      MasterServers: [
          '10.10.1.1'
          '10.10.4.1'
      ]
  }
  {
      Name: 'fabrikam.com'
      MasterServers: [
          '192.168.26.1'
      ]
  }
]

var storageBlobDataReader = '/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'

param postFix string = utcNow()


resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' existing = {
  name: vmName
}

resource sta 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: staName
}

resource staBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' existing = {
  name: 'default'
  parent: sta
}

resource staContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' existing = {
  name: 'guestconfigs'
  parent: staBlob
}

resource staAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(staContainer.id, storageBlobDataReader, vm.id)
  scope: staContainer
  properties: {
    roleDefinitionId: storageBlobDataReader
    principalId: vm.identity.principalId
  }
}

resource cse 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: cseName
  parent: vm
  dependsOn: [
    staAssignment
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: postFix
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File Configure-DnsServer.ps1 -Forwarders ${cseForwarders} -ConditionalForwarders ${ConditionalForwarders}'
      //storageAccountName: staName
      // to use a system managed id for access:
      managedIdentity: {}
      fileUris: [
        'https://staagocsetst.blob.core.windows.net/guestconfigs/Configure-DnsServer.ps1'
      ]
    }
  }
}
