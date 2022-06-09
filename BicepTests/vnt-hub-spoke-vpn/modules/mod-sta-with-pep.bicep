param name string
param location string
param sku string = 'Standard_LRS'
param kind string = 'StorageV2'
param blobContainers array = []
param vnetId string
param subnet string 
param dnsSubscriptionId string
param dnsResourceGroup string

var dnsDomain = 'privatelink.blob.${environment().suffixes.storage}'

resource sta 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    allowBlobPublicAccess: false
  }
}

resource staBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: 'default'
  parent: sta
}

resource staContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = [for container in blobContainers: {
  name: container
  parent: staBlob
}]


resource dns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnsDomain
  scope: resourceGroup(dnsSubscriptionId, dnsResourceGroup)
}

// note: for each storage service you need to create a pep. To keep it easy we only create a blob one
// also: if you have multiple resources with peps, its probably better to decouple this from the storage account and create
// a separate module!
resource pep 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${name}-blob-pep'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${name}-pep'
        properties: {
          privateLinkServiceId: sta.id
          groupIds: [
            'blob'
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
