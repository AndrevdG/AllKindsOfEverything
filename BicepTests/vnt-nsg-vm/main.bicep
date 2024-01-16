param projectName string 
param adminUserName string
@secure()
param adminPassword string


//optional parameters
param vmSize string = 'Standard_B2s'
param location string = resourceGroup().location
param subnetName string = 'snt-${projectName}'
param vmBaseName string = 'vm${replace(projectName, '-', '')}'
param vmCount int = 1
@allowed([
  '2019-Datacenter'
  '2022-datacenter'
  '2022-datacenter-core-smalldisk'
])
param windowsOSVersion string = '2022-datacenter'
param vnetName string = 'vnt-${projectName}'
param nsgName string = 'nsg-${projectName}'
param staName string = 'sta${replace(projectName, '-', '')}'


param postFix string = utcNow()

module nsg 'nsg.bicep' = {
  name: 'nsg-${projectName}-${postFix}'
  params: {
    nsgName: nsgName
    location: location
    allowedIps: [
      '31.151.214.218/32'
    ]
  }
}

module vn 'vnet.bicep' = {
  name: 'vnt-${projectName}-${postFix}'
  params: {
    vnetName: vnetName
    addressPrefixes:[
      '192.168.20.0/24'
    ]
    nsgId: nsg.outputs.nsgId
    subnets: [
      {
        name: subnetName
        addressPrefix: '192.168.20.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
  }
}

module sta './storage.bicep' = {
  name: 'sta-${projectName}-${postFix}'
  params: {
    staName: staName
  }
}

module vm './workstation.bicep' = [for i in range(1, vmCount): {
  name: '${vmBaseName}${padLeft(i,2,'0')}-${postFix}'
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    vmSize: vmSize
    location: location
    windowsOSVersion: windowsOSVersion
    createPip: true
    diskNameOs: 'osd-${vmBaseName}${padLeft(i,2,'0')}'
    nicName: 'nic-${vmBaseName}${padLeft(i,2,'0')}'
    vmName: '${vmBaseName}${padLeft(i,2,'0')}'
    pipName: 'pip-${vmBaseName}${padLeft(i,2,'0')}'
    subnetRef: '${vn.outputs.vnetId}/subnets/${subnetName}'
  }
}]

module vmcse './dns-csextension.bicep' = [for i in range(0, vmCount): {
  name: 'cse-${vm[i].name}'
  params: {
    staName: staName
    vmName: vm[i].outputs.vmName
  }
}]
