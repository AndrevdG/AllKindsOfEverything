param name string
param location string
param vnetId string
param subnet string 
param dnsResourceGroup string = ''
param dnsSubscriptionId string = ''
param roles array = []
param tenantId string = subscription().tenantId
param networkDefaultAction string = 'Deny'
param ipRules array = []

var _roleDefinitionId = {
  'Key Vault Administrator': {
    id: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  }
  'Key Vault Certificates Officer': {
    id: 'a4417e6f-fecd-4de8-b567-7b0420556985'
  }
  'Key Vault Crypto Officer': {
    id: '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
  }
  'Key Vault Crypto Service Encryption User': {
    id: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
  }
  'Key Vault Crypto User': {
    id: '12338af0-0e69-4776-bea7-57ae8d297424'
  }
  'Key Vault Reader	': {
    id: '21090545-7ca7-4776-b22c-e363652d74d2'
  }
  'Key Vault Secrets Officer': {
    id: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
  }
  'Key Vault Secrets User': {
    id: '4633458b-17de-408a-b874-0445c86b69e6'
  }
}

var dnsDomain = 'privatelink.vaultcore.azure.net'

resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: name
  location: location
  properties: {
    tenantId: tenantId
    sku:{
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: networkDefaultAction
      ipRules: [for ip in ipRules: {
        value: ip
      }]
    }
  }
}

resource dns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnsDomain
  scope: resourceGroup(dnsSubscriptionId, dnsResourceGroup)
}

resource pep 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${name}-pep'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${name}-pep'
        properties: {
          privateLinkServiceId: kv.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnetId}/subnets/${subnet}'
    }
  }
}

resource pepdns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  name: '${pep.name}/default'
  properties: {
   privateDnsZoneConfigs:[
     {
      name: replace(dnsDomain, '.', '-')
      properties: {
        privateDnsZoneId: dns.id
      }
     }
   ] 
  }
}

resource role 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = [for r in roles: {
  name: guid(kv.id, r.objectId, _roleDefinitionId[r.role].id)
  scope: kv
    properties: {
    principalId: r.objectId
    roleDefinitionId: '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${_roleDefinitionId[r.role].id}'
  }
}]
