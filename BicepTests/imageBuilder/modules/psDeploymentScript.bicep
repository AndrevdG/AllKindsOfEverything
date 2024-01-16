param name string
param location string
param identityId string = ''
param azPowerShellVersion string = '10.3'
@allowed([
  'Always'
  'OnSuccess'
  'OnExpiration'
])
param cleanupPreference string = 'Always'
param retentionInterval string = 'P1D'
param timeout string = 'PT1H'
param scriptContent string
param arguments string = ''
param containerName string = 'deploymentScripts'

param timestamp string = utcNow()

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  identity: !empty(identityId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  } : null
  properties: {
    azPowerShellVersion: azPowerShellVersion
    retentionInterval: retentionInterval
    timeout: timeout
    cleanupPreference: cleanupPreference
    forceUpdateTag: timestamp
    scriptContent: scriptContent
    arguments: !empty(arguments) ? arguments : null
    containerSettings: !empty(containerName) ? {
      containerGroupName: containerName
    } : null
  }
}
