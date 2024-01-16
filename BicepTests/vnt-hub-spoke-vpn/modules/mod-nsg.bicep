param nsgName string
param location string = resourceGroup().location
param allowedIps array = []
param allowInternetForwarding bool = false

var securityRules = [for (ip, i) in allowedIps: {
  name: 'allow-from-${replace(replace(ip, '.', '-'), '/', '_')}'
  properties: {
    access: 'Allow'
    priority: 490 + 10 * i
    direction: 'Inbound'
    protocol: '*'
    sourceAddressPrefix: ip
    sourcePortRange: '*'
    destinationPortRanges: [
      '3389'
      '22'
      '443'
      '80'
    ]
    destinationAddressPrefix: '*'
  }
}]

var InternetForwarding = allowInternetForwarding ? {
  name: 'allow-forwarded-peering-traffic'
  properties: {
    access: 'Allow'
    priority: 4000
    direction: 'Inbound'
    protocol: '*'
    sourceAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
    destinationAddressPrefix: 'Internet'
    destinationPortRange: '*'
  }

} : null

var nsgRules = allowInternetForwarding ? union (securityRules, array(InternetForwarding)) : securityRules

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: nsgRules
  }
}

output nsgId string = nsg.id
