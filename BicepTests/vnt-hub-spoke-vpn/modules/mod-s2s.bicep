targetScope = 'resourceGroup'

param name string
param lgwname string
param vgwName string
param lgwAddresses array
param lgwIpAddress string
@allowed([
  'AES128'
  'AES192'
  'AES256'
  'GCMAES128'
  'GCMAES192'
  'GCMAES256'
])
param ipsecEncryption string
@allowed([
  'MD5'
  'SHA1'
  'SHA256'
  'GCMAES128'
  'GCMAES192'
  'GCMAES256'
])
param ipsecIntegrity string
@allowed([
  'AES128'
  'AES192'
  'AES256'
  'GCMAES128'
  'GCMAES256'
])
param ikeEncryption string
@allowed([
  'MD5'
  'SHA1'
  'SHA256'
  'SHA384'
  'GCMAES128'
  'GCMAES256'
])
param ikeIntegrity string
@allowed([
  'None'
  'DHGroup1'
  'DHGroup2'
  'DHGroup14'
  'DHGroup2048'
  'ECP256'
  'ECP384'
  'DHGroup24'
])
param dhGroup string
@allowed([
  'None'
  'PFS1'
  'PFS2'
  'PFS2048'
  'ECP256'
  'ECP384'
  'PFS24'
  'PFS14'
  'PFSMM'
])
param pfsGroup string
@secure()
param sharedKey string
// Optional parameters
param saLifeTimeSeconds int = 27000
param saDataSizeKilobytes int = 102400000
param location string
param connectionType string = 'IPsec'
param connectionProtocol string = 'IKEv2'
param enableBgp bool = false

resource vgw 'Microsoft.Network/virtualNetworkGateways@2020-11-01' existing = {
  name: vgwName
}

resource lgw 'Microsoft.Network/localNetworkGateways@2020-11-01' = {
  name: lgwname
  location: location
  properties:{
    localNetworkAddressSpace:{
      addressPrefixes: lgwAddresses
    }
    gatewayIpAddress: lgwIpAddress
  }
}

resource con 'Microsoft.Network/connections@2020-11-01' = {
  name: name
  location: location
  properties:{
    virtualNetworkGateway1: {
      id: vgw.id
      properties: vgw.properties
    }
    localNetworkGateway2: {
      id: lgw.id
      properties: lgw.properties
    }
    sharedKey: sharedKey
    connectionType: connectionType
    connectionProtocol: connectionProtocol
    enableBgp: enableBgp
    ipsecPolicies: vgw.properties.sku.tier != 'Basic' ? [
      {
        saLifeTimeSeconds: saLifeTimeSeconds
        saDataSizeKilobytes: saDataSizeKilobytes
        ipsecEncryption: ipsecEncryption
        ipsecIntegrity: ipsecIntegrity
        ikeEncryption: ikeEncryption
        ikeIntegrity: ikeIntegrity
        dhGroup: dhGroup
        pfsGroup: pfsGroup
      }
    ] : null
  }
}
