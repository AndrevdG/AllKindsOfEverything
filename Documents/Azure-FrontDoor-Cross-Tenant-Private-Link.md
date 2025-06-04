# Introduction

One of the features of private link is the ability to privately access resources within Azure. The most common scenario is the creation of Private Endpoints for securing access to a PaaS resources like Azure App Service. However, there are other scenarios possible, like for instance extending your own services. For instance, as a Managed Service Provider, you can create a service for your customers and allow customers access to these services using Private Link. This scenario obviously works across Azure Tenants.

Another scenario where Private Link / Private Endpoint can be utilized is for Azure Front Door (AFD). This allows you to securely link AFD to an Azure resource (f.i. App Service, Storage Account, etc). For more information, you can check [AFD - Private Link](https://learn.microsoft.com/en-us/azure/frontdoor/private-link)

However, according to the documentation, this is only possible within the same tenant. Or is it?

**IMPORTANT: The following is provided as thought experiment! Even though it works, Azure Support have confirmed this to be an unsupported scenario. Do not use in production!**

# Attempt 1
The easiest way to try this would be with Az Cli. One of the configuration paths allows you to specify a resourceId for the resource you would like to link to AFD.
For instance, something like:

```Bash
az afd origin create \
  --enabled-state Enabled \
  --resource-group myRsg \
  --origin-group-name origin1 \
  --origin-name originName1
  --profile-name myAfd01
  --host-name somehostname.swedencentral-01.azurewebsites.net \
  --origin-host-header somehostname.swedencentral-01.azurewebsites.net \
  --http-port 80 \
  --https-port 443 \
  --priority 1 \
  --weight 500 \
  --enable-private-link true \
  --private-link-location SwedenCentral \
  --private-link-request-message 'AFD app service origin Private Link request.' \
  --private-link-resource /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Web/sites/someAppService \
  --private-link-sub-resource-type sites
```

Sadly, this does not quite work:
