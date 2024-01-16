Param (
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$true)]
    [string[]]$recipient,
    [Parameter(Mandatory=$false)]
    [string]$configFileFullname = (Join-Path -Path $PSScriptRoot -ChildPath "messagebird.config.json")
)

Function Get-ApiKey {
    param (
        [Parameter(Mandatory=$true)]
        [object]$config
    )
    # check if secureApiKey is set
    if ([string]::IsNullOrEmpty($config.secureApiKey) -and [string]::IsNullOrEmpty($config.apiKey)){
        throw "Config file does not contain an API key"
    # presuming an apikey is at least 5 characters
    } elseif ($config.apiKey.Length -gt 5) {
        Write-Information "Writing new secure API key to config file"
        # if the config does not contain a member secureApiKey, add it
        if (-Not ($config | Get-Member -MemberType NoteProperty -Name secureApiKey)){
        $config | 
            Add-Member `
                -MemberType NoteProperty `
                -Name secureApiKey `
                -Value (ConvertTo-SecureString -String $config.apiKey -AsPlainText -Force | ConvertFrom-SecureString)
        } else {
            # if the config does contain a member secureApiKey, update it
            $config.secureApiKey = ConvertTo-SecureString -String $config.apiKey -AsPlainText -Force | ConvertFrom-SecureString
        }
        $config.apiKey = ""
    }
    return $config
}

Function Get-Config {
    param (
        [Parameter(Mandatory=$true)]
        [string]$configFileFullname
    )
    # check if config file exists
    if (-Not (Test-Path -Path $configFileFullname)){
        throw "Config file not found: $configFileFullname"
    }
    $config = Get-Content -Path $configFileFullname -Raw | ConvertFrom-Json
    if (-Not $config.secureApiKey -or -Not [string]::IsNullOrEmpty($config.apiKey)) {
        # Either the config does not contain a secureApiKey or apiKey is not empty
        $config = Get-ApiKey -config $config
        # Write out the config file (Note: the secureApiKey is only reable by the user that created it on the machine it was created on)
        $config | ConvertTo-Json | Set-Content -Path $configFileFullname
    }
    return $config
}

Function Send-MessageBirdMsg {
    param (
        [Parameter(Mandatory=$true)]
        [string]$message,
        [Parameter(Mandatory=$true)]
        [string[]]$recipient,
        [Parameter(Mandatory=$true)]
        [string]$originator,
        [Parameter(Mandatory=$true)]
        [string]$apiKey
    )
    $body = @{
        recipients = $recipient -join ','
        originator = $originator
        body = $message
    }
    $headers = @{
        Authorization = "AccessKey $apiKey"
    }
    $uri = "https://rest.messagebird.com/messages"
    $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -Headers $headers
    return $response
}

Function Get-MessageBirdDeliveryStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$messageId,
        [Parameter(Mandatory=$true)]
        [string]$apiKey,
        [Parameter(Mandatory=$false)]
        [int]$timeoutInMins = 5
    )
    $now = Get-Date
    $headers = @{
        Authorization = "AccessKey $apiKey"
    }
    $uri = ("https://rest.messagebird.com/messages/{0}" -f $messageId)
    while ((Get-Date) -ne $now.AddMinutes($timeoutInMins)) {
        Try {
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        } Catch {
            if (-Not ($_.Exception.Response.StatusCode -eq "NotFound")) {
                throw $_
            }
        }
        if ($response.recipients.totalCount -eq ($response.recipients.totalDeliveryFailedCount + $response.recipients.totalDeliveredCount)) {
            break
        }
        Start-Sleep -Seconds 5
    }
    return $response
}

Write-Information ("Script starting at {0}" -f (Get-Date -Format FileDateTime))
$config = Get-Config -configFileFullname $configFileFullname
# Extract and decrypt the secureApiKey
$apiKey = $config.secureApiKey | ConvertTo-SecureString | ConvertFrom-SecureString -AsPlainText

# send the message
Write-Information ("Sending message to {0} with originator {1}" -f ($recipient -join ','), $config.originator)
$response = Send-MessageBirdMsg -message $message -recipient $recipient -originator $config.originator -apiKey $apiKey

# get the delivery status
Write-Information ("Sending status for message with id {0}" -f $response.id)
$status = Get-MessageBirdDeliveryStatus -messageId $response.id -apiKey $apiKey

if ($response.recipients.totalDeliveryFailedCount -gt 0) {
    Write-Warning "Message delivery failed"
    $status.recipients.items | Where-Object {-Not [int]$_.statusErrorCode -eq 0}  | ForEach-Object {
        Write-Warning ("message failed to deliver to recipient {0}, status {1}({2})" -f $_.recipient, $_.statusReason, $_.statusErrorCode)
    }
}
$status.recipients.items | Where-Object {[int]$_.statusErrorCode -eq 0}  | ForEach-Object {
    Write-Information ("Message delivered to recipient {0}, status {1})" -f $_.recipient, $_.statusReason)
}