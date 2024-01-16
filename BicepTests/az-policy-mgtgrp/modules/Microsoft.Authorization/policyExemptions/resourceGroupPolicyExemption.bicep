targetScope = 'resourceGroup'

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

module resourceExemptions './resourcePolicyExemption.bicep' = [for resexemption in items(exemptions.?resource ?? {}) : {
  name: 'policy-grp-exempt-${resexemption.key}'
  params: {
    resourceName: resexemption.key
    resourceType: resexemption.value.resourceType
    exemptions: resexemption.value.data
    policyAssignmentId: policyAssignmentId
  }
}]
