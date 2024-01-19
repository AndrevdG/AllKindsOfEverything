Param (
    [Parameter(Mandatory=$true)]
    [string]$Message,

    [Parameter(Mandatory=$false)]
    [string[]]$Recipient,

    [Parameter(Mandatory=$false)]
    [string]$ConfigFilePath = (Join-Path -Path $PSScriptRoot -ChildPath "messagebird.config.json")
)


Function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$LogFilePath,

        [Parameter(Mandatory=$false)]
        [switch]$Warning,

        [Parameter(Mandatory=$false)]
        [switch]$LogOnly
    )
    $now = Get-Date -UFormat "%m-%d-%Y %R %Z"
    $outMessage = ("{0} {1}" -f $now, $message)

    if (-Not $LogOnly) {
        if ($Warning) {
            Write-Warning $outMessage
            $outMessage = ("{0} WARNING {1}" -f $now, $message)
        } else {
            Write-Host $outMessage
        }
    }

    if ($LogFilePath) {
        $outMessage | Out-File -FilePath $LogFilePath -Append
    }
}

Function Get-LogFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFileBaseName,

        [Parameter(Mandatory=$false)]
        [string]$LogFileRelativePath
    )
    $logFileName = $LogFileBaseName.Substring(0, $LogFileBaseName.lastIndexOf('.'))
    $logExtension = $LogFileBaseName.Split('.')[-1]

    if ($LogFileRelativePath) {
        $logFilePath = Join-Path -Path $PSScriptRoot -ChildPath $LogFileRelativePath
        [void](New-Item -Path $logFilePath -ItemType Directory -Force)
    } else {
        $logFilePath = $PSScriptRoot
    }

    $logFilePath = Join-Path -Path $logFilePath -ChildPath ("{0}-{1}.{2}" -f $logFileName, (Get-Date -Format FileDate), $logExtension)
    if (-Not (Test-Path -Path $LogFilePath)){
        $log = New-Item -Path $LogFilePath -ItemType File
    } else {
        $log = Get-Item -Path $logFilePath
    }
    return $log.FullName
}

Function Get-ApiKey {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    # check if secureApiKey is set
    if ([string]::IsNullOrEmpty($Config.secureApiKey) -and [string]::IsNullOrEmpty($Config.apiKey)){
        Write-Log -Message "Config file does not contain an API key" -LogFilePath $logFile -Warning -LogOnly
        throw "Config file does not contain an API key"
    # presuming an apikey is at least 5 characters
    } elseif ($Config.apiKey.Length -gt 5) {
        Write-Log -message "Writing new secure API key to config file" -LogFilePath $logFile
        # check the key to make sure it is valid
        $headers = @{
            Authorization = ("AccessKey {0}" -f $config.apiKey)
        }
        $uri = "https://rest.messagebird.com/balance"
        Try {
            [Void](Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop)
        } Catch {
            Write-Log -Message ("API key is not valid: {0}" -f $_.Exception.Message) -LogFilePath $logFile -Warning -LogOnly
            throw "API key is not valid"
        }
        # if the config does not contain a member secureApiKey, add it
        if (-Not ($Config | Get-Member -MemberType NoteProperty -Name secureApiKey)){
        $Config | 
            Add-Member `
                -MemberType NoteProperty `
                -Name secureApiKey `
                -Value (ConvertTo-SecureString -String $config.apiKey -AsPlainText -Force | ConvertFrom-SecureString)
        } else {
            # if the config does contain a member secureApiKey, update it
            $Config.secureApiKey = ConvertTo-SecureString -String $Config.apiKey -AsPlainText -Force | ConvertFrom-SecureString
        }
        $Config.apiKey = ""
    }
    return $Config
}

Function Update-Config {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFilePath,

        [Parameter(Mandatory=$true)]
        [object]$Config
    )
   
    if (-Not $Config.secureApiKey -or -Not [string]::IsNullOrEmpty($Config.apiKey)) {
        # Either the config does not contain a secureApiKey or apiKey is not empty
        $Config = Get-ApiKey -config $Config
        # Write out the config file (Note: the secureApiKey is only reable by the user that created it on the machine it was created on)
        $Config | ConvertTo-Json | Set-Content -Path $ConfigFilePath
    }
    return $Config
}

Function Send-MessageBirdMsg {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [string[]]$Recipient,
        [Parameter(Mandatory=$true)]
        [string]$Originator,
        [Parameter(Mandatory=$true)]
        [string]$ApiKey
    )
    $body = @{
        recipients = $Recipient -join ','
        originator = $Originator
        body = $Message
    }
    $headers = @{
        Authorization = "AccessKey $ApiKey"
    }
    $uri = "https://rest.messagebird.com/messages"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -Headers $headers
    } Catch {
        Write-Log -Message ("Error sending message: {0}" -f $_.Exception.Message) -LogFilePath $logFile -Warning -LogOnly
        throw $_
    }
    return $response
}

Function Get-MessageBirdDeliveryStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$MessageId,
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,
        [Parameter(Mandatory=$true)]
        [int]$StatusTimeoutInMins
    )
    $now = Get-Date
    $headers = @{
        Authorization = "AccessKey $ApiKey"
    }
    $uri = ("https://rest.messagebird.com/messages/{0}" -f $MessageId)
    while ((Get-Date) -lt $now.AddMinutes($StatusTimeoutInMins)) {
        Try {
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        } Catch {
            # it can take a moment for the message to be available through the API
            if (-Not ($_.Exception.Response.StatusCode -eq "NotFound")) {
                Write-Log -Message ("Error getting message status: {0}" -f $_.Exception.Message) -LogFilePath $logFile -Warning -LogOnly
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
if (-Not (Test-Path -Path $ConfigFilePath)){
    throw "Config file not found: $ConfigFilePath"
}
$config = Get-Content -Path $ConfigFilePath -Raw | ConvertFrom-Json

# start logging
if ($config.writeLog) {
    $logFile = Get-LogFile -LogFileRelativePath $config.logFileRelativePath -LogFileBaseName $config.logFileBaseName
} else {
    $logFile = ""
}

$config = Update-Config -ConfigFilePath $ConfigFilePath -Config $config
# Extract and decrypt the secureApiKey
$apiKey = $config.secureApiKey | ConvertTo-SecureString -ErrorAction Stop | ConvertFrom-SecureString -AsPlainText
$statusTimeoutInMins = $config.statusTimeoutInMins ? $config.statusTimeoutInMins : 5

$recipient = $recipient ? $recipient : $config.recipient
if (-Not $recipient) {
    Write-Log -message "No recipient specified" -LogFilePath $logFile -Warning -LogOnly
    throw "No recipient specified"
}

# send the message
Write-Log -Message ("Sending message '{0}'" -f $message) -LogFilePath $logFile
Write-Log -Message ("Sending message to {0} with originator {1}" -f ($recipient -join ','), $config.originator) -LogFilePath $logFile
$response = Send-MessageBirdMsg -Message $message -Recipient $recipient -Originator $config.originator -ApiKey $apiKey

# get the delivery status
Write-Log -Message  ("Checking status for message with id {0}" -f $response.id) -LogFilePath $logFile
$status = Get-MessageBirdDeliveryStatus -MessageId $response.id -ApiKey $apiKey -StatusTimeoutInMins $statusTimeoutInMins

if ($response.recipients.totalDeliveryFailedCount -gt 0) {
    Write-Log -Message "Message delivery failed" -LogFilePath $logFile -Warning
    $status.recipients.items | Where-Object {-Not [int]$_.statusErrorCode -eq 0}  | ForEach-Object {
        Write-Log -Message ("message failed to deliver to recipient {0}, status {1}({2})" -f $_.recipient, $_.statusReason, $_.statusErrorCode) -LogFilePath $logFile -Warning
    }
}
$status.recipients.items | Where-Object {[int]$_.statusErrorCode -eq 0}  | ForEach-Object {
    Write-Log -Message ("Message delivered to recipient {0}, status {1})" -f $_.recipient, $_.statusReason) -LogFilePath $logFile
}