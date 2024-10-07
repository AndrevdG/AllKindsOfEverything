param storageAccountName string = 'fnstorage${uniqueString(subscription().id)}'
param location string = resourceGroup().location
param planName string = 'fnplan-${uniqueString(subscription().id)}'
param wsName string = 'fnws-${uniqueString(subscription().id)}'
param aiName string = 'fnai-${uniqueString(subscription().id)}'
param fnName string = 'fn-${uniqueString(subscription().id)}'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: {
    displayName: 'Storage Account'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Allow'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storage
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: 'app-package'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: wsName
  tags: {
    displayName: 'Log Analytics Workspace'
  }
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: aiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

resource appInsightsName_Basic 'microsoft.insights/components/pricingPlans@2017-10-01' = {
  parent: appInsights
  name: 'current'
  properties: {
    cap: 1
    planType: 'Basic'
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: fnName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.properties.primaryEndpoints.blob}app-package'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 40
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'powershell'
        version: '7.4'
      }
    }
  }
}

resource fn_appSettings 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    azurewebjobsstorage__accountname: storage.name
    FUNCTIONS_EXTENSION_VERSION: '~4'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
  }
}

resource blobDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
}

resource rbac_fn 'Microsoft.Authorization/roleAssignments@2022-04-01' =  {
  name: guid(storage.id, functionApp.name)
  scope: storage
  properties: {
    roleDefinitionId: blobDataOwnerRoleDefinition.id
    principalId: functionApp.identity.principalId
  }
}


output storageAccountName string = storage.name
output planName string = plan.name
output fnName string = functionApp.name