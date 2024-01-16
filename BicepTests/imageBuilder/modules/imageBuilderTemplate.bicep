param location string
param name string
param identityId string
param runOutputName string
param galleryImageId string
param stagingResourceGroup string

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-07-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    stagingResourceGroup: stagingResourceGroup
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2022-Datacenter'
      version: 'latest'
    }
    customize: [
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 40
      }
      {
        type: 'PowerShell'
        name: 'Install Choco and Vscode'
        inline: [
          'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(\'https://community.chocolatey.org/install.ps1\'))'
          'choco install -y vscode'
        ]
      }
    ]
    distribute: [ {
        type: 'SharedImage'
        galleryImageId: galleryImageId
        runOutputName: runOutputName
        replicationRegions: [
          location
        ]
      } ]
  }
}
