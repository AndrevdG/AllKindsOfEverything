#TODO: Create a copilot kind of function that can be used to generate code snippets
# works with gpt-3.5-turbo by setting the temparature low, like 0.3
# and setting a system prompt like "You are a strict assistant, translating natural language to PowerShell statements. Please do not explain, just write code."
# examples of prompts:
#
#   "get user admin_ago from active directory"
#   "get all users from active directory domain mydomain.local in the Organizational Unit Admins"



# class describing a message in a chat
class aichatmessage {
    [ValidateSet("system", "user", "assistant")][string]$role
    [ValidateNotNullOrEmpty()][string]$content

    aichatmessage(
        [string]$role, 
        [string]$content) {
            $this.role = $role
            $this.content = $content
    }
}

# class describing a chat with openai
class aichat {
    [aichatmessage[]]$messages
    [string]$model
    [int]$temperature 
    [int]$max_tokens
    [int]$n

    aichat(
        [string]$chatcontext, [aichatconfig]$chatconfig) {
            $this.messages += [aichatmessage]::new("system", $chatcontext)
            $this.model = $chatconfig.model
            $this.temperature = $chatconfig.temperature
            $this.max_tokens = $chatconfig.max_tokens
            $this.n = $chatconfig.n
    }

    aichat(
        [aichatconfig]$chatconfig) {
            $this.model = $chatconfig.model
            $this.temperature = $chatconfig.temperature
            $this.max_tokens = $chatconfig.max_tokens
            $this.n = $chatconfig.n
    }

    [void]addquestion( 
        [string]$content) {
            $this.messages += [aichatmessage]::new("user", $content)
    }

    [void]addresponse( 
        [string]$content) {
            $this.messages += [aichatmessage]::new("assistant", $content)
    }

    [void]updateConfig(
        [aichatconfig]$chatconfig) {
            $this.model = $chatconfig.model
            $this.temperature = $chatconfig.temperature
            $this.max_tokens = $chatconfig.max_tokens
            $this.n = $chatconfig.n
    }
    
}

# class describing openai configuration options
class aichatconfig {
    [string]$model = "gpt-3.5-turbo"
    [int]$temperature = 0.9
    [int]$max_tokens = 0
    [int]$n = 1

    aichatconfig(
        [string]$model,
        [int]$temperature,
        [int]$max_tokens,
        [int]$n) {
            $this.model = $model
            $this.temperature = $temperature
            # $this.max_tokens = $max_tokens
            $this.n = $n
        }
}



Function _InvokeOpenAiMessage {
    param(
        [aichat]$chat
    )
    

    $headers = @{
        "Content-Type" = "application/json"
        Authorization = ("Bearer {0}" -f (ConvertFrom-SecureString -SecureString $script:openaiKey -AsPlainText))
    }

    # can probably be done better...
    if ($chat.max_tokens -eq 0) {
        $body = $chat | Select-Object -ExcludeProperty max_tokens | ConvertTo-Json -Depth 10
    } else {
        $body = $chat | ConvertTo-Json -Depth 10
    }

    $response = Invoke-RestMethod -Method POST -Uri "https://api.openai.com/v1/chat/completions" -Headers $headers -Body $body
    if ($response) {
        $chat.addresponse($response.choices[0].message.content)
        $response.choices[0].message.content
        Write-Host ("Total tokens used in conversation: {0}" -f $response.usage.total_tokens)
    } else {
        Write-Error "No response from OpenAI"
    }
}

Function Set-OpenAiChatConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$model = "gpt-3.5-turbo",

        [Parameter(Mandatory=$false)]
        [ValidateRange(0,2)]
        [int]$temperature = 0.9

        # [Parameter(Mandatory=$false)]
        # [int]$max_tokens = 0

        # [Parameter(Mandatory=$false)]
        # [int]$n = 1
    )

    # set the chat config, n is static for now
    $script:defaultChatConfig = [aichatconfig]::new($model, $temperature, 0, 1)
    if (Get-Variable chat -Scope Script -ErrorAction SilentlyContinue) {
        $script.chat.updateConfig($script:defaultChatConfig)
    }

}

Function Set-OpenAiCodeConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$model = "gpt-3.5-turbo",

        [Parameter(Mandatory=$false)]
        [ValidateRange(0,2)]
        [int]$temperature = 0.2
    )

    # set the chat config, n is static for now
    $script:defaultCodeConfig = [aichatconfig]::new($model, $temperature, 0, 1)

}

Function Set-OpenAiApiKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [securestring]$apiKey
    )
    if ($apiKey.Length -eq 0){
        $apiKey = Read-Host "Provide your OpenAI API key" -AsSecureString
    }
    [securestring]$script:openaiKey = $apiKey
}

Function New-OpenAiChat {
    [Alias("newGptChat")]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$chatContext
    )

    if ([string]::IsNullOrEmpty($chatContext)) {
        #$chatContext = Read-Host "What is the chat context? e.g. You are a PowerShell Expert"
        $script:chat = [aichat]::new($script:defaultChatConfig)
    } else {
        $script:chat = [aichat]::new($chatContext, $script:defaultChatConfig)
    }

}

Function Get-OpenAiChat {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$Raw
    )

    if ($Raw) {
        $script:chat
    } else {
        $script:chat.messages
    }
}

Function Get-OpenAiCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$Raw
    )

    if ($Raw) {
        $script:code
    } else {
        $script:code.messages
    }
}

Function Add-OpenAiMessage {
    [Alias("gptChat")]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true)]
        [string]$question
    )
    # check if the api key has been set    
    if ($script:openaiKey.Length -eq 0) {
        Write-Debug "Setting the OpenAI API key"
        Set-OpenAiApiKey
    }

    # check if the chat config has been set
    if ([string]::IsNullOrEmpty($script:defaultChatConfig)) {
        Write-Debug "Setting the chat config"
        Set-OpenAiChatConfig
    }

    # create a new chat if none exists
    if ([string]::IsNullOrEmpty($script:chat)) {
        Write-Debug "Creating a new chat"
        New-OpenAiChat
    }

    # check if a question was passed in
    if ([string]::IsNullOrEmpty($question)) {
        Write-Debug "No question was passed in, prompting for one"
        $question = Read-Host "What is the question?"
    }

    # add the question to the chat and query openai
    Write-Debug "Adding the question to the chat and querying OpenAI"
    $script:chat.addquestion($question)
    _InvokeOpenAiMessage

}

Function New-OpenAiCodeCompletion {
    [Alias("gptCode")]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true)]
        [string]$question,

        [Parameter(Mandatory=$false)]
        [string]$language = "PowerShell"
    )
    # check if the api key has been set    
    if ($script:openaiKey.Length -eq 0) {
        Write-Debug "Setting the OpenAI API key"
        Set-OpenAiApiKey
    }

    # check if the chat config has been set
    if ([string]::IsNullOrEmpty($script:defaultCodeConfig)) {
        Write-Debug "Setting the code config"
        Set-OpenAiCodeConfig
    }

    # create a new code completion
    $script:code = [aichat]::new(
        #("You are a strict assistant, translating natural language to {0} statements. Please do not explain, just write code." -f $language),
        ("You are a {0} generator that returns only valid code, no explanations, no examples" -f $language),
        $script:defaultCodeConfig
    )

    # check if a question was passed in
    if ([string]::IsNullOrEmpty($question)) {
        Write-Debug "No question was passed in, prompting for one"
        $question = Read-Host "Describe what code you are looking for: "
    }

    # add the question to the chat and query openai
    Write-Debug "Adding the question to the chat and querying OpenAI"
    $script:code.addquestion($question)
    _InvokeOpenAiMessage -chat $script:code

}


Export-ModuleMember -Function *-OpenAi* -Alias gptChat, newGptChat, gptCode