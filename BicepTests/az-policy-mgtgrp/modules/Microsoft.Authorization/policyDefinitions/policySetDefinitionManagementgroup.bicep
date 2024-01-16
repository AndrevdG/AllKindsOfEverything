targetScope = 'managementGroup'

param name string
param values object

var _builtinPolicies = loadJsonContent('../../../configs/builtinPolicyReference.json')


resource initiative_resource 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: name
  properties: {
    displayName: values.?displayName ?? name
    description: values.?description ?? ''
    policyType: 'Custom'
    parameters: values.?parameters ?? {}
    policyDefinitions: [for policy in items(values.policyDefinitions): {
      policyDefinitionId: policy.value.?policyTypeCustom ?? false ? managementGroupResourceId('Microsoft.Authorization/policyDefinitions', policy.value.?policyName ?? policy.key) : tenantResourceId('Microsoft.Authorization/policyDefinitions', _builtinPolicies[policy.value.?policyName ?? policy.key].name)
      parameters: policy.value.?parameters ?? {}
      groupNames: policy.value.?groupNames ?? []
      policyDefinitionReferenceId: policy.key
    }]
    policyDefinitionGroups: map(values.?policyDefinitionGroups ?? [], name => {
        name: name
      })
  }
}

