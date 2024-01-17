Param (
    [Parameter(Mandatory=$true)]
    [string]$message,

    [Parameter(Mandatory=$true)]
    [string[]]$recipient,

    [Parameter(Mandatory=$false)]
    [string]$configFileFullname = (Join-Path -Path $PSScriptRoot -ChildPath "messagebird.config.json")
)


Function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$message,

        [Parameter(Mandatory=$false)]
        [string]$logFileFullname,

        [Parameter(Mandatory=$false)]
        [switch]$warning,

        [Parameter(Mandatory=$false)]
        [switch]$logOnly
    )
    $now = Get-Date -UFormat "%m-%d-%Y %R %Z"
    $outMessage = ("{0} {1}" -f $now, $message)

    if (-Not $logOnly) {
        if ($warning) {
            Write-Warning $outMessage
            $outMessage = ("{0} WARNING {1}" -f $message)
        } else {
            Write-Host $outMessage
        }
    }

    if ($logFileFullname) {
        $outMessage | Out-File -FilePath $logFileFullname -Append
    }
}

Function Get-LogFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$logFileBaseName,

        [Parameter(Mandatory=$false)]
        [string]$logFileRelativePath
    )
    $logFileName = $logFileBaseName.Substring(0, $logFileBaseName.lastIndexOf('.'))
    $logExtension = $logFileBaseName.Split('.')[-1]

    if ($logFileRelativePath) {
        $logFilePath = Join-Path -Path $PSScriptRoot -ChildPath $logFileRelativePath
        [void](New-Item -Path $logFilePath -ItemType Directory -Force)
    }
    $logFileFullname = Join-Path -Path $logFilePath -ChildPath ("{0}-{1}.{2}" -f $logFileName, (Get-Date -Format FileDate), $logExtension)
    if (-Not (Test-Path -Path $logFileFullname)){
        $log = New-Item -Path $logFileFullname -ItemType File
    } else {
        $log = Get-Item -Path $logFileFullname
    }
    return $log.FullName
}

Function Get-ApiKey {
    param (
        [Parameter(Mandatory=$true)]
        [object]$config
    )
    # check if secureApiKey is set
    if ([string]::IsNullOrEmpty($config.secureApiKey) -and [string]::IsNullOrEmpty($config.apiKey)){
        Write-Log -message "Config file does not contain an API key" -logFileFullname $logFile -warning -logOnly
        throw "Config file does not contain an API key"
    # presuming an apikey is at least 5 characters
    } elseif ($config.apiKey.Length -gt 5) {
        Write-Log -message "Writing new secure API key to config file" -logFileFullname $logFile
        # check the key to make sure it is valid
        $headers = @{
            Authorization = ("AccessKey {0}" -f $config.apiKey)
        }
        $uri = "https://rest.messagebird.com/balance"
        Try {
            [Void](Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop)
        } Catch {
            Write-Log -message ("API key is not valid: {0}" -f $_.Exception.Message) -logFileFullname $logFile -warning -logOnly
            throw "API key is not valid"
        }
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

Function Update-Config {
    param (
        [Parameter(Mandatory=$true)]
        [string]$configFileFullname,

        [Parameter(Mandatory=$true)]
        [object]$config
    )
   
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
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -Headers $headers
    } Catch {
        Write-Log -message ("Error sending message: {0}" -f $_.Exception.Message) -logFileFullname $logFile -warning -logOnly
        throw $_
    }
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
            # it can take a moment for the message to be available through the API
            if (-Not ($_.Exception.Response.StatusCode -eq "NotFound")) {
                Write-Log -message ("Error getting message status: {0}" -f $_.Exception.Message) -logFileFullname $logFile -warning -logOnly
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

# Get config
if (-Not (Test-Path -Path $configFileFullname)){
    throw "Config file not found: $configFileFullname"
}
$config = Get-Content -Path $configFileFullname -Raw | ConvertFrom-Json

# start logging
if ($config.writeLog) {
    $logFile = Get-LogFile -logFileRelativePath $config.logFileRelativePath -logFileBaseName $config.logFileBaseName
} else {
    $logFile = ""
}

$config = Update-Config -configFileFullname $configFileFullname -config $config
# Extract and decrypt the secureApiKey
$apiKey = $config.secureApiKey | ConvertTo-SecureString | ConvertFrom-SecureString -AsPlainText

# send the message
Write-Log -message ("Sending message '{0}'" -f $message) -logFileFullname $logFile
Write-Log -message ("Sending message to {0} with originator {1}" -f ($recipient -join ','), $config.originator) -logFileFullname $logFile
$response = Send-MessageBirdMsg -message $message -recipient $recipient -originator $config.originator -apiKey $apiKey

# get the delivery status
Write-Log -message  ("Checking status for message with id {0}" -f $response.id) -logFileFullname $logFile
$status = Get-MessageBirdDeliveryStatus -messageId $response.id -apiKey $apiKey

if ($response.recipients.totalDeliveryFailedCount -gt 0) {
    Write-Log -message "Message delivery failed" -logFileFullname $logFile -warning
    $status.recipients.items | Where-Object {-Not [int]$_.statusErrorCode -eq 0}  | ForEach-Object {
        Write-Log -message ("message failed to deliver to recipient {0}, status {1}({2})" -f $_.recipient, $_.statusReason, $_.statusErrorCode) -logFileFullname $logFile -warning
    }
}
$status.recipients.items | Where-Object {[int]$_.statusErrorCode -eq 0}  | ForEach-Object {
    Write-Log -message ("Message delivered to recipient {0}, status {1})" -f $_.recipient, $_.statusReason) -logFileFullname $logFile
}