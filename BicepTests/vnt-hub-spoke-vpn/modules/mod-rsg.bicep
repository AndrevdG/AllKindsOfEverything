targetScope = 'subscription'

param name string
param location string
param resourceGroupAssignments array = []

// only used for deployment names
param postFix string = utcNow()

resource rsg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
}

module roleAssignments 'mod-rsg-roleassignments.bicep' = {
  scope: resourceGroup(name)
  dependsOn: [
    rsg
  ]
  name: 'ra-${name}-${postFix}'
  params: {
    resourceGroupAssignments: resourceGroupAssignments
  }
}
