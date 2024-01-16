####
## https://gist.github.com/19WAS85/5424431
####

# Create a http listener
$server = [System.Net.HttpListener]::new()

# Add a binding
$server.Prefixes.Add("http://localhost:8080/")

# Start server
$server.Start()

if ($server.IsListening) {
    Write-Host "HTTP Server listening"
}

while ($server.IsListening) {

    $ctx = $server.GetContext()

    if ($ctx.Request.HttpMethod -eq 'GET' -and $ctx.Request.RawUrl -eq '/') {
        # log request
        Write-Host ("{0} is requesting {1} on {2} " -f $ctx.Request.UserHostAddress, $ctx.Request.HttpMethod, $ctx.Request.RawUrl)
        
        # create response message
        [string]$html = "<h1>Hello World!<h1>"
        
        # respond to request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert to bytes
        $ctx.Response.ContentLength64 = $buffer.Length
        $ctx.Response.OutputStream.Write($buffer, 0, $buffer.Length) # stream to browser
        $ctx.Response.Close()

    }

    if ($ctx.Request.HttpMethod -eq 'GET' -and $ctx.Request.RawUrl -eq '/HealthCheck') {
        # log request
        Write-Host ("{0} is requesting {1} on {2} " -f $ctx.Request.UserHostAddress, $ctx.Request.HttpMethod, $ctx.Request.RawUrl)
        
        
        # create response message
        [string]$html = "<h1>Hello World!<h1>"
        
        # respond to request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert to bytes
        $ctx.Response.ContentLength64 = $buffer.Length
        $ctx.Response.OutputStream.Write($buffer, 0, $buffer.Length) # stream to browser
        $ctx.Response.Close()

    }

    if ($ctx.Request.HttpMethod -eq 'GET' -and $ctx.Request.RawUrl -eq '/KillServer') {
        # log request
        Write-Host ("{0} is requesting {1} on {2} " -f $ctx.Request.UserHostAddress, $ctx.Request.HttpMethod, $ctx.Request.RawUrl)
        Write-Host "gracefully exit requested"
        
        # create response message
        [string]$html = "<h1>Terminating service<h1>"
        
        # respond to request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert to bytes
        $ctx.Response.ContentLength64 = $buffer.Length
        $ctx.Response.OutputStream.Write($buffer, 0, $buffer.Length) # stream to browser
        $ctx.Response.Close()

        $server.Stop()
        exit 0

    }

}