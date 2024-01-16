targetScope = 'managementGroup'

param name string
param values object


resource policy_resource 'Microsoft.Authorization/policyDefinitions@2021-06-01' =  {
  name: name
  properties: {
    policyType: 'Custom'
    mode: values.?mode ?? 'All'
    displayName: values.?displayName ?? name
    description: values.?description ?? ''
    parameters: values.?parameters ?? {}
    policyRule: values.policyRule
  }
}
