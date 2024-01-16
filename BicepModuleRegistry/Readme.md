# Introduction

This folder contains two folders:
- modules: this folder will contain all the modules that will be uploaded to the container registry
- registry: this folder contains the (basic) deployment files for the deployment of the registry itself

Besides this folder, there is also an associated github workflow in the .github folder in the root
(.github/bicep-module-registry.yml)

# Modules folder

__(Stub documentation)__

Add a new directory under the `modules` folder in your local bicep-registry-modules repository with the path in lowercase following the pattern `<ModuleGroup>/<ModuleName>`. Typical `<ModuleGroup>` names are Azure resource provider names without the `Microsoft.` prefix, but other names are also allowed as long as they make sense. `<ModuleName>` should be a singular noun or noun phrase. `<ModuleName>` should be a singular noun or noun phrase. Child modules should be placed side by side with parent modules to maintain a flat file structure. For examples:

- `compute/vm-with-public-ip`
- `web/containerized-web-app`
- `web/containerized-web-app-config`

The structure is based of the structure for the public [github repo](https://github.com/Azure/bicep-registry-modules/blob/main/CONTRIBUTING.md)

# Registry deployment files
Documentation to be added.