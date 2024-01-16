param staName string
param location string = resourceGroup().location
param staSkuName string = 'Standard_LRS'
param staKind string = 'StorageV2'
param createGuestConfigContainer bool = true

resource sta 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: staName
  location: location
  sku: {
    name: staSkuName
  }
  kind: staKind
}

resource staBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = if (createGuestConfigContainer) {
  name: 'default'
  parent: sta
}

resource staContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = if (createGuestConfigContainer) {
  name: 'guestconfigs'
  parent: staBlob
}
