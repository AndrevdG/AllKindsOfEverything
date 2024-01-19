# Sending Messagebird SMS
This script allows for a simple way to send SMS via Messagebird. The script will wait max 5 minutes for delivery status by default and report the delivery status in the logging.

## Parameters
The script accepts the following parameters:

**[Required] _message_**  
A string containing the message you want to be send through SMS  
Example: "This is a message"

**[Optional] _recipient_**  
An array of strings containing the (internation) mobile numbers you want to send the SMS to  
Example 1: "+31612312345"  
Example 2: "+31612312345", "+31612312354"  

**[Optional] _configFileFullname_**  
A string containing configuration file and full path. If not provided the script expects a config file 'messagebird.config.json'
in the same location as the script.  
Example: "d:\temp\messagebird.config.json"

So for instance:
.\send-messagebirdmsg.ps1 -message "Sending messages was never more easy" -recipient "+31612312354" -configFileFullname "messagebird.config.test.json"

## Configuration file
The configuration file should look like this:
```json
{
  "apiKey": "",
  "originator": "+31231231123",
  "recipient": [],
  "secureApiKey": "",
  "statusTimeoutInMins": 5,
  "writeLog": true,
  "logFileRelativePath": "/log",
  "logFileBaseName": "messagebird.log"
}
```
- **_apiKey_**: Cleartext string containing the apiKey (see below)
- **_originator_**: The phonenumber that is configured as originator within the MessageBird SMS Channel
- **_recipient_**: The array of phonenumbers that will receive the message. Only used if not set as parameter when calling the script
- **_secureApiKey_**: This value will be written by the script, do not fill manually (see below)
- **_statusTimeoutInMins_**: The amount of time the script waits until all SMS delivery is successfull. If not provided it defaults to 5 minutes
- **_writeLog_**: Boolean. If true the script will log to file
- **_logFileRelativePath_**: The relative logpath (to the script location) where the log files will be created. If not provided the log file will be created in the same location as the script
- **_logFileBaseName_**: The base name for the logfile. The filename will be updated with the current date. For instance if "messagebird.log" is provided, the logfile could be named: messagebird-20240117.log

### apiKey and secureApiKey
**_If the script will be running under a different account than the user copying the files, make sure that this account has permissions to update the config file(!)_**
When preparing the script for first use, you have to set the apiKey to authenticate to MessageBird as a cleartext string in the configuration file. When the script is run the first time, it will read the apiKey. If the apiKey is valid and authentication to MessageBird succeeds, the script will encrypt it and write it out to the config file as secureApiKey. The cleartext apiKey will be removed at this point.
**_Please Note: The secureApiKey is only readable for the user that the script was run under the first time and ONLY on the machine the string was encrypted on!_**
If the apiKey needs to be updated, you can just set a new value in the configuration file and run the script again (using the correct user context) .