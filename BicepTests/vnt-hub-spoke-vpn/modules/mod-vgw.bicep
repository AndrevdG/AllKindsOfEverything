param name string
param location string
@allowed([
  'Basic'
  'VpnGw1'
  'VpnGw2'
])
param tier string
param vnetId string

resource vgwpip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${name}-pip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vgw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' = {
  name: name
  location: location
  properties: {
    activeActive: false
    enableBgp: false
    vpnType: 'RouteBased'
    sku: {
      name: tier
      tier: tier
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: vgwpip.id
          }
          subnet: {
            id: '${vnetId}/subnets/GatewaySubnet'
          }
        }
      }
    ]
  }
}


// ipAddress is not filled at the first deployment for dynamic pip... resolved this differently
//output vgwPublicIp string = vgwpip.properties.ipAddress
