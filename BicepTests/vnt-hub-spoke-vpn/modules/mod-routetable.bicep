param vnetName string
param location string
param subnets array
param fwIp string = ''
param spokeAddressRanges array = []

// only used for deployment names
param postFix string = utcNow()

// Gateway subnet (vpn) should have the spoke routes but not (probably) a default route
var routesGwSn = [for spoke in spokeAddressRanges: {
  name: 'route-${spoke.name}'
    properties: {
      addressPrefix: spoke.range
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: fwIp
    }
}]

// Routes for spokes should have a default route, no other (subnet) routes should be needed in this scenario
var routesPerSn =  [ 
   {
    name: 'default'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: fwIp
    }
  } 
]

// Create route table, subnets in the hub should have both default route and spoke subnet routes pointing to fw
resource rt 'Microsoft.Network/routeTables@2021-08-01' = [for (subnet, i) in subnets: if (!(contains(subnet, 'noRouteTable') && subnet.noRouteTable == true)) {
  name: 'sn-${subnet.name}-rt'
  location: location
  properties: {
    routes: subnet.name == 'GatewaySubnet'? routesGwSn : endsWith(vnetName, '-hub') ? union(routesGwSn, routesPerSn): routesPerSn
  }
}]

module existing_vnet 'util-existing-vnet-config.bicep' = {
  name: 'existing-${vnetName}-${postFix}'
  params: {
    subnets: subnets
    vnetName: vnetName
  }
}

@batchSize(1)
resource update_sn 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' = [for (subnet, i) in subnets: if (!(contains(subnet, 'noRouteTable') && subnet.noRouteTable == true)) {
  name: '${vnetName}/${subnet.name}'
  dependsOn: [
    existing_vnet
  ]
  properties: {
    addressPrefix: subnet.range
    routeTable: !empty(rt[i].id) ? {
      id: rt[i].id
    } : null
    networkSecurityGroup: contains(existing_vnet.outputs.existing_sn[i].properties, 'networkSecurityGroup') && !empty(existing_vnet.outputs.existing_sn[i].properties.networkSecurityGroup.id) ? {
      id: existing_vnet.outputs.existing_sn[i].properties.networkSecurityGroup.id
    } : null
    privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : null
  }
}]


output routesPerSn array = routesPerSn
