targetScope = 'subscription'

param projectName string 

// only used for deployment names
param postfix string = utcNow()

var config = json(replace(loadTextContent('configs/config.json'), '__projectname__', projectName))
var vnetConfig = union(config.spoke, array(config.hub))

module vnets 'modules/mod-vnet.bicep' = [for item in vnetConfig: {
  scope: resourceGroup(contains(item, 'subscriptionId') ? item.subscriptionId : subscription().subscriptionId, item.rsg.name)
  name: '${item.vnet.name}-${postfix}'
  params:{
    vnetName: item.vnet.name
    location: item.rsg.location
    addressPrefixes: item.vnet.addressSpace
    subnets: item.vnet.subnets
    //nsgId: item.vnet.name == config.hub.vnet.name ? nsg.outputs.nsgId : ''
  }
}]


//output spokeAddressRanges array = spokeAddressRanges
