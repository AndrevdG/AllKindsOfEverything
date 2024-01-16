
param name string
param location string
param sku string

var disabledPublicAccess = {
  networkAccessPolicy: 'DenyAll'
  publicNetworkAccess: 'Disabled'
}

var properties = union(getDisk.outputs.properties, disabledPublicAccess)

module getDisk 'util-get-managed-disk.bicep' = {
  name: 'get-disk'
  params: {
    name: name
  }
}

resource disk 'Microsoft.Compute/disks@2022-03-02' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: properties
}
