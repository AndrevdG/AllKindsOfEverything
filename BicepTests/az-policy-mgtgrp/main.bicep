targetScope = 'managementGroup'

param location string = deployment().location

var _customPolicyDefinitions = loadJsonContent('configs/customPolicyDefinitions.json')
var _customPolicySetDefinitons = loadJsonContent('configs/customPolicySetDefinitions.json')
var _policyAssignments = loadJsonContent('configs/policyAssignments.json')


module policydefinition './modules/Microsoft.Authorization/policyDefinitions/policyDefinitionManagementGroup.bicep'  = [for pol in items(_customPolicyDefinitions): {
  name: 'deploy-policy-${pol.key}'
  params: {
    name: pol.key
    values: pol.value
  }
}]

module policysetdefinitions './modules/Microsoft.Authorization/policyDefinitions/policySetDefinitionManagementGroup.bicep'  = [for initiative in items(_customPolicySetDefinitons): {
  name: 'deploy-initiative-${initiative.key}'
  dependsOn: [
    policydefinition
  ]
  params: {
    name: initiative.key
    values: initiative.value
  }
}]


@batchSize(1)
module policyset_assignment './modules/Microsoft.Authorization/policyAssignments/managementGroupAssignment.bicep' = [for init in items(_policyAssignments.?initiatives ?? {}): {
  name: 'deploy-assignment-${init.key}'
  dependsOn: [
    policysetdefinitions
  ]
  params: {
    knownSubscriptionIds: {}
    location: location
    policyName: init.key
    isPolicySet: true
    values: init.value
  }
}]

@batchSize(1)
module policy_assignment './modules/Microsoft.Authorization/policyAssignments/managementGroupAssignment.bicep' = [for pol in items(_policyAssignments.?policies ?? {}): {
  name: 'deploy-assignment-${pol.key}'
  dependsOn: [
    policydefinition
    policyset_assignment
  ]
  params: {
    knownSubscriptionIds: {}
    location: location
    policyName: pol.key 
    values: pol.value
  }
}]
