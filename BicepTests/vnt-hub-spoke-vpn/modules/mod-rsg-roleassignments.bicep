param resourceGroupAssignments array = []

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac
resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = [ for assignment in resourceGroupAssignments : {
  name: assignment.roleDefinitionId
}]

resource rabc 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [ for (assignment, i) in resourceGroupAssignments : {
  name: guid(resourceGroup().id, assignment.objectId, assignment.roleDefinitionId)
  properties: {
    principalId: assignment.objectId
    principalType: assignment.principalType
    roleDefinitionId: roleDefinition[i].id
  }
}]
