targetScope = 'resourceGroup'

param resourceName string
param resourceType string
param exemptions array
param policyAssignmentId string


// resource scope exemptions are not possible from bicep, needing a arm template to do this
module policyExemption 'resourcePolicyExemption.json' = [for (exemption,i) in exemptions: {
  name: 'deploy-exemption-${resourceName}-${i}'
  params: {
    name: exemption.name
    description: exemption.?description ?? ''
    displayName: exemption.?displayName ?? exemption.name
    exemptionCategory: exemption.exemptionCategory
    expiresOn: exemption.?expiryDate ?? ''
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: array(exemption.?policyReferenceId)
    resourceName: resourceName
    resourceType: resourceType
  }
}]

