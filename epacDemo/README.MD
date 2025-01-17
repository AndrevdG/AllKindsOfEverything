# EPAC Demo
This has a very sparse policy set and no pipelines. The only intent of this folder is to create a sample deployment with epac, 
done from a PowerShell shell, so that it is a little easier to show the core functionality.

For more information, see the documentation: https://azure.github.io/enterprise-azure-policy-as-code/

## Initial

Make sure all settings in .\Definitions\global-settings.jsonc are correct for the current environment
(Partial) Example:
_The 'epac-' suffixed management groups are for development/testing so are excluded for the 'live' environment. For the dev environment the opposite is done_
```json
    {
      "pacSelector": "tenant",
      "cloud": "AzureCloud",
      "tenantId": "9620a59d-ee15-467b-9db2-3ea57cc86153",
      "deploymentRootScope": "/providers/Microsoft.Management/managementGroups/automagical-tst",
      "desiredState": {
        "strategy": "full",
        "excludedPolicyAssignments": [],
        "keepDfcSecurityAssignments": false,
        "excludedScopes": [],
        "excludedPolicySetDefinitions": [],
        "excludedPolicyDefinitions": []
      },
      "globalNotScopes": [
        "/subscriptions/e3209603-e27d-448a-9a43-5654d86e02ca"
      ],
      "managedIdentityLocation": "westeurope"
    }
```
Short property list (for more info see [the documentation](https://azure.github.io/enterprise-azure-policy-as-code/settings-global-setting-file/))
- pacSelector: Logical name for the EPAC environment (best practise: 'tenant' and 'dev' environments)
- cloud: Cloud environment (Mostly 'AzureCloud')
- tenantId: Allows for multi tenant environments (the dev/test deployment can also be in a different tenant)
- deploymentRootScope: Deployment scope for Policy and Policy Set definitions. Any assignments can only be defined at this scope or child scopes (recursive)
- globalNotScopes: Scopes that are excluded from all policy assignments

# Definitions
For the sake of the demo, only a few Policy sets (and policies) are added to the Definitions folder:
- required-tags-on-resourcegroups: A custom policy set which references (twice) a custom policy that denies a new resource group without a specific tag
- Enforce-Guardrails-Storage: Borrowed from the ALZ policies and enforces some common best practises when deploying storage. This set contains both custom policies (included in the Definitions folder) and builtin policies

# Assignments
To keep things simple, there are just two example assignments:
- Demo-Root-Default: Assigned to subscription level and assigns the required-tags-on-resourcegroups policy set
- Demo-Resourcegroup-Default: Assigned to a resource group and assings the Enforce-Guardrails-Storage policy set

# (Manual) deployment
Because this is just meant as a simple demo, no pipelines are included. The full install for Epac does provide pipelines (Github Actions or Azure Devops pipeline)

To be able to run the Epac scripts, you need to install two modules:
  Install-Module Az -Scope CurrentUser
  Install-Module EnterprisePolicyAsCode -Scope CurrentUser

Deployment of Epac normally consists of two phases:
- Planning: In this phase no write actions are performed, only a prediction of actions is displayed. This generally also throws an error if you did something wrong
  - Build-DeploymentPlans.ps1
- Deployment: This is the phase where actual changes are made. This consists of two steps:
  - Deploy-PolicyPlan.ps1: Deploys the policies definitions and assigns the policies
  - Deploy-RolesPlan.ps1: Policies that have Modify or DeployIfNotExists effects require a managed identity in order to work. This step creates the required identities
    _This demo contains one such policy: Deploy-Storage-sslEnforcement_

The pipelines also include an additional pipeline for remediation. 
- New-AzRemediationTask: The policies with an effect of Modify or DeployIfNotExists will only make changes when:
  - A resource is created or updated
  - A remediation job is started (which this cmdlet does)



