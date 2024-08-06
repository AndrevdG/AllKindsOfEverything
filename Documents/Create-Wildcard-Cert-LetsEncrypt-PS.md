In order to test encrypted communications you will often need a certificate. You can create a selfsigned certificate for this, but this often
causes issues or at least makes it more difficult to test things. The better alternative is to create a [Let's Encrypt](https://letsencrypt.org/docs/faq/). 
This does require you to be able to change dns related settings for this domain.

In my case, cloudflare is used as a DNS provider for a custom domain. The following steps decribe (shortly) how to create a (wildcard) certificate for
the custom domain.

We will be using the [Posh-ACME](https://poshac.me/) PowerShell module to create the certificate.

- Install the module (if needed)
```PowerShell
Install-Module -Name Posh-ACME
```
- Next, you will need to create an API key for the cloudflare plugin (if needed, of course). See the [Posh-ACME documenation](https://poshac.me/docs/v4/Plugins/Cloudflare/)
- We can use the generated API key to simply request a certificate. The Posh-ACME cmdlet will use the API key to automatically set the correct DNS records in order for
the request to be successfully created:
```PowerShell
$pArgs = @{
    CFToken = (Read-Host 'API Token' -AsSecureString)
}
New-PACertificate *.example.com -AcceptTOS -Plugin Cloudflare -PluginArgs $pArgs | Format-List
```

Note: by default the generated certificates will be saved in a local folder within your user profile, like:
```
C:\Users\<UserName>\AppData\Local\Posh-ACME\LE_PROD\<id>\<DomainName>
```
If you used Format-List as in the example, the paths will be displayed when the cmdlet finishes
