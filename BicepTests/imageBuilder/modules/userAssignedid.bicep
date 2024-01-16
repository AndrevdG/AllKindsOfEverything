targetScope = 'resourceGroup'

param location string
param name string

resource uaId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
}

output uaId string = uaId.id
output uaPrincipalId string = uaId.properties.principalId

