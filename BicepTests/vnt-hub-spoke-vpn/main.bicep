targetScope = 'subscription'

param projectName string
param deployHubSpoke bool = true
param deployOnPrem bool = true
param deployVpnCon bool = false

// only used for deployment names
param postfix string = utcNow()


var config = json(replace(loadTextContent('configs/config.json'), '__projectname__', projectName))


module hubspoke 'create-hubspoke.bicep' = if (deployHubSpoke) {
  name: 'deploy-hub-spoke-${postfix}'
  params: {
    config: config
  }
}

// the dependency is only needed because of linking the vnet to the private dns zone(s) in the hub
module onprem 'create-onprem.bicep' = if (deployOnPrem) {
  name: 'deploy-onprem-${postfix}'
  dependsOn:[
    hubspoke
  ]
  params: {
    config: config
  }
}

module vpnConnections 'create-vpn-connections.bicep' = if ((deployOnPrem && deployHubSpoke) || deployVpnCon) {
  name: 'deploy-vpn-connections-${postfix}'
  dependsOn: [
    hubspoke
    onprem
  ]
  params: {
    config: config
  }
}
