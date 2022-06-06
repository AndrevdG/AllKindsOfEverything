
param hubConfiguration object
param spokeConfiguration array
param nsgId string

// Optional
param deployPostfix string = utcNow()

var vnetConfiguration = concat(array(hubConfiguration), spokeConfiguration)

targetScope = 'subscription'

// Create vnets
module vnetDeployment './modules/vnet.bicep' = [for i in range(0, length(vnetConfiguration)): {
  scope: resourceGroup(vnetConfiguration[i].vnetSubscriptionId,vnetConfiguration[i].vnetRsg)
  name: '${vnetConfiguration[i].vnetName}-${deployPostfix}'
  params:{
    vnetName: vnetConfiguration[i].vnetName
    location: vnetConfiguration[i].location
    addressPrefixes: vnetConfiguration[i].vnetAddressSpace
    subnets: vnetConfiguration[i].snetConfig
    nsgId: nsgId
  }
}]

// Create peerings on the hub
module hubPeerings './modules/vnet-hub-peering.bicep' = {
  scope: resourceGroup(hubConfiguration.vnetSubscriptionId,hubConfiguration.vnetRsg)
  name: 'hubPeering-${deployPostfix}'
  dependsOn: [
    vnetDeployment
  ]
  params: {
    hubConfiguration: hubConfiguration
    spokeConfiguration: spokeConfiguration
  }
}

// Create peerings on the spoke(s)
module spokePeerings './modules/vnet-spoke-peering.bicep' = [for vnet in spokeConfiguration: {
  scope: resourceGroup(vnet.vnetSubscriptionId,vnet.vnetRsg)
  name: '${vnet.vnetName}-peering-${deployPostfix}'
  dependsOn: [
    vnetDeployment
  ]
  params:{
    hubConfiguration: hubConfiguration
    vnetName: vnet.vnetName
  }
}]

