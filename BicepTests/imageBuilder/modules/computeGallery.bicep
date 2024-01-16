param name string
param location string

param imageDefinition object = {
    name: 'server2022-GoldenImage'
    location: location
    properties: {
      identifier: {
        offer: 'WindowsServer'
        publisher: 'Automagical'
        sku: 'WinSrv2022'
      }
      osState: 'generalized'
      osType: 'windows'
    }
  }


resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: name
  location: location
}

resource imageDefinition_res 'Microsoft.Compute/galleries/images@2022-03-03' = {
  name: imageDefinition.name
  parent: gallery
  location: imageDefinition.location
  properties: {
    identifier: imageDefinition.properties.identifier
    osState: imageDefinition.properties.osState
    osType: imageDefinition.properties.osType
  }
}

output galleryId string = gallery.id
output imageDefintionId string = imageDefinition_res.id



