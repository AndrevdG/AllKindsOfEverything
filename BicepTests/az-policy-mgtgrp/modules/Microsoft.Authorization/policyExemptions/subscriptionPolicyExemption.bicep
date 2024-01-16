targetScope = 'subscription'

param exemptions object
param policyAssignmentId string

resource policyExemption 'Microsoft.Authorization/policyExemptions@2022-07-01-preview' = [for (exemption,i) in exemptions.?data ?? [] : {
  name: '${exemption.name}-${i}'
  properties: {
    expiresOn: exemption.?expiryDate
    displayName: exemption.?displayName ?? exemption.name
    description: exemption.?description ?? ''
    exemptionCategory: exemption.exemptionCategory
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: array(exemption.?policyReferenceId)
  }
}]

module resourceGroupExemptions './resourceGroupPolicyExemption.bicep' = [for grpexemption in items(exemptions.?resourcegroup ?? {}) : {
  scope: resourceGroup(grpexemption.key)
  name: 'policy-grp-exempt-${grpexemption.key}'
  params: {
    exemptions: grpexemption.value
    policyAssignmentId: policyAssignmentId
  }
}]
