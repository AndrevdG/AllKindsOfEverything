Param (
	[String[]]$FoldersToClean,
	[int]$RetentionDays = 30,
    [string]$Extension = "log",
    [switch]$Recurse
)

ForEach ($folder in $FoldersToClean){
	# Only attempt to clean if folder exists
    $Parameters = @{
        Path = $folder
        Filter = ("*.{0}" -f $Extension)
    }
    if ($Recurse) {$Parameters += @{Recurse = $true}}
	if (Test-Path $folder) {
		Get-ChildItem @Parameters | Where-Object {$_.LastWriteTime -lt (Get-Date).adddays(-$RetentionDays)} | Remove-Item -Force
	} else {
		Write-Warning ("Folder {0} does not exist or we don't have access. Skipping!")
	}
}
