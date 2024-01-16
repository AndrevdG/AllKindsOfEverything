targetScope = 'subscription'

param location string = 'westeurope'

param rsgName string = 'rg-imagebuilder'
param galleryName string = 'imageBuilderGallery'
param imageName string = 'server2022-GoldenImage'
param imageBuilderTemplateName string = '${imageName}-Template'

resource rsg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rsgName
  location: location
}

// user assigned identity for running the image builder
module templateUAID './modules/userAssignedid.bicep' = {
  name: 'templateUAID'
  scope: rsg
  params: {
    location: location
    name: 'imageBuilderUserAssignedId'
  }
}

// user assigned identity for running the deployment script
module scriptUAID './modules/userAssignedid.bicep' = {
  name: 'scriptUAID'
  scope: rsg
  params: {
    location: location
    name: 'deploymentScriptUserAssignedId'
  }
}

// For ease using contributor, this should probably be more restrictive ;)
// See: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-permissions-powershell#allow-vm-image-builder-to-distribute-images
module rbacTemplate './modules/rsgRoleAssignment.bicep' = {
  name: 'rbacTemplate'
  scope: rsg
  params: {
    principalId: templateUAID.outputs.uaPrincipalId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  }
}

// For ease using contributor, this should probably be more restrictive ;)
// See: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template#configure-the-minimum-permissions
module rbacScript './modules/rsgRoleAssignment.bicep' = {
  name: 'rbacScript'
  scope: rsg
  params: {
    principalId: scriptUAID.outputs.uaPrincipalId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  }
}

module gallery 'modules/computeGallery.bicep' = {
  name: 'gallery'
  scope: rsg
  params: {
    name: galleryName
    location: location
    imageDefinition: {
      name: imageName
      location: location
      properties: {
        identifier: {
          offer: 'WindowsServer'
          publisher: 'Automagical'
          sku: 'WinSrv2022'
        }
        osState: 'generalized'
        osType: 'windows'
      }
    }
  }
}

module removeTemplateIfExist 'modules/psDeploymentScript.bicep' = {
  scope: rsg
  name: 'removeTemplateIfExist'
  params: {
    name: 'removeTemplateIfExist'
    location: location
    identityId: scriptUAID.outputs.uaId
    cleanupPreference: 'OnSuccess'
    arguments: '-name ${imageBuilderTemplateName} -resourceGroupName ${rsgName}'
    scriptContent: '''
    param([string]$name, [string]$resourceGroupName)
    install-module az.imagebuilder -force
    Get-AzImageBuilderTemplate -Name $name -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue `
      | Remove-AzImageBuilderTemplate -ErrorAction SilentlyContinue
    '''
  }
}


module imageBuilderTemplate 'modules/imageBuilderTemplate.bicep' = {
  scope: rsg
  name: imageBuilderTemplateName
  dependsOn: [
    removeTemplateIfExist
  ]
  params: {
    galleryImageId: gallery.outputs.imageDefintionId
    identityId: templateUAID.outputs.uaId
    location: location
    stagingResourceGroup: '${rsgName}-temp'
    name: imageBuilderTemplateName
    runOutputName: imageName
  }
}
