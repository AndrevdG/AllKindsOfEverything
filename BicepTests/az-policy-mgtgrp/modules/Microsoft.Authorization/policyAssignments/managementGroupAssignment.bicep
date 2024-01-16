targetScope = 'managementGroup'

param policyName string
param isPolicySet bool = false
param values object
param location string
param knownSubscriptionIds object = {}

var _builtinPolicies = loadJsonContent('../../../configs/builtinPolicyReference.json')
var _policyParameterValues = loadJsonContent('../../../configs//policyParameterValues.json')
var _assignmentName = take(values.?name ?? policyName, 24)
var _systemAssignedIdentity = values.?systemAssignedIdentity ?? false ? {
  type: 'SystemAssigned'
} : null
var _policyDefinitionId = isPolicySet ? values.?policyTypeCustom ?? false ? managementGroupResourceId('Microsoft.Authorization/policysetdefinitions', policyName) : tenantResourceId('Microsoft.Authorization/policysetdefinitions', _builtinPolicies[policyName].name) : values.?policyTypeCustom ?? false ? managementGroupResourceId('Microsoft.Authorization/policydefinitions', policyName) : tenantResourceId('Microsoft.Authorization/policydefinitions', _builtinPolicies[policyName].name)

resource assignment 'Microsoft.Authorization/policyAssignments@2021-06-01' =  {
  name: _assignmentName
  location: location
  identity: _systemAssignedIdentity
  properties: {
    policyDefinitionId: _policyDefinitionId
    parameters: toObject(values.?parameters ?? [], param => param, param => _policyParameterValues[param])
    nonComplianceMessages: values.?nonComplianceMessages ?? []
  }
}

module subscriptionExemptions '../policyExemptions/subscriptionPolicyExemption.bicep' = [for subexemption in items(values.?exemptions ?? {}) : if (!empty(subexemption)) {
  scope: subscription(contains(knownSubscriptionIds, subexemption.key) ? knownSubscriptionIds[subexemption.key] : subexemption.key)
  name: 'policy-sub-exempt-${subexemption.key}'
  params: {
    exemptions: subexemption.value
    policyAssignmentId: assignment.id
  }
}]
