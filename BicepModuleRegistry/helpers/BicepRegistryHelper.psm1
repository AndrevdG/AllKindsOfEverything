function _GetChangedModulesFromGh {
    param (
        [Parameter(Mandatory = $true)]
        [securestring]
        $token,

        [Parameter(Mandatory = $true)]
        [string]
        $ghRepo,

        [Parameter(Mandatory = $true)]
        [string]
        $ghRef
    )

    Write-Verbose ("Getting changed bicep modules from GitHub repo {0} at ref {1}" -f $ghRepo, $ghRef)
    # Get the commit based on the provided ref (SHA or branch name)
    $Parameters = @{
        Method = "Get"
        Authentication = "OAuth"
        Token = $token
        Uri = ("https://api.github.com/repos/{0}/commits/{1}" -f $ghRepo, $ghRef)
        Headers = @{ "Accept" = "application/vnd.github" }
        ResponseHeadersVariable = "Response"
        ErrorAction = "Stop"
    }
    

    do {
        Write-Verbose ("Fetching files from {0}" -f $Parameters.Uri)
        $commit = Invoke-RestMethod @Parameters

        # Get the list of bicep modules changed in the commit
        $files += $commit.files.filename | Where-Object {$_ -match "(?!.*metadata.json)(?!.*README.MD).*\/modules\/.*"}

        # If there are multiple pages, continue to get the next page until there are no more pages
        # See: https://docs.github.com/en/rest/guides/using-pagination-in-the-rest-api?apiVersion=2022-11-28
        $nextUri = (($response.Link -split "," | Where-Object {$_ -match "rel=`"next`""}) -split ';')[0] -replace "<|>", ""
        $Parameters.Uri = $nextUri

    } while (-Not [string]::IsNullOrWhiteSpace($nextUri))
    
    Write-Verbose ("Found {0} changed bicep module files" -f $files.Count)

    # Get the unique list of changed modules from the changed files
    $modules = $files | ForEach-Object {
        # E.g. BicepModuleRegistry/modules/containerregistry/registry/main.bicep -> containerregistry/registry
        if ($_) {"{0}/{1}" -f $_.split('/')[2], $_.split('/')[3]}
    } | Select-Object -Unique

    Write-Verbose ("Found {0} changed bicep modules" -f $modules.Count)

    return $modules
}



<#
    $acr = (az acr show -n acrautomagicaleu -g rg-we-bicepregistry) | ConvertFrom-Json -Depth 9
    az bicep publish --file .\modules\containerregistry\registry\main.bicep --target "br:$($acr.loginServer)/bicep/modules/containerregistry/registry:v0.1"
#>