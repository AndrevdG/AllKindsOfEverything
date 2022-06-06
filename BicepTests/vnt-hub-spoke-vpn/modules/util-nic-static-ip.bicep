param name string
param ipconfigName string
param ipAddress string
param subnetId string
param enableIPForwarding bool
param publicIpId object = {}
param location string


resource nicStatic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: ipconfigName
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: ipAddress
          subnet: {
            id: subnetId
          }
          publicIPAddress: !empty(publicIpId) ? publicIpId : null
        }
      }
    ]
    enableIPForwarding: enableIPForwarding
  }
}

output staticIP string = nicStatic.properties.ipConfigurations[0].properties.privateIPAddress
