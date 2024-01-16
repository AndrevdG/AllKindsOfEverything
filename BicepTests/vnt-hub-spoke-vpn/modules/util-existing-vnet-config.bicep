param vnetName string
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: vnetName
}

resource existing_sn 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = [for (subnet, i) in subnets: if (!(contains(subnet, 'noRouteTable') && subnet.noRouteTable == true)) {
  parent: vnet
  name: subnet.name
}]

output existing_sn array = [for (subnet, i) in subnets : existing_sn[i] ]
