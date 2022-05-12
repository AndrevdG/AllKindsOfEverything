param nsgName string
param location string = resourceGroup().location
param allowedIps array 

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [for (ip, i) in allowedIps: {
     name: 'allow-from-${replace(ip, '.', '-')}'
     properties: {
       access: 'Allow'
       priority: 490+10*i
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
  }
}

output nsgId string = nsg.id
