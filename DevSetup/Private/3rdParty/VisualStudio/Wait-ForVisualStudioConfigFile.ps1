Function Wait-ForVisualStudioConfigFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$ConfigFilePath,
        [int]$TimeoutSeconds = 60,
        [int]$PollIntervalSeconds = 2
    )

    $ElapsedSeconds = 0

    Write-StatusMessage "- Waiting for Visual Studio config file to be created" -ForegroundColor Gray -NoNewline -Indent 4 -Width 112

    while ($ElapsedSeconds -lt $TimeoutSeconds) {
        if ((Test-Path -Path $ConfigFilePath) -and (Get-Item $ConfigFilePath).Length -gt 0) {
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds $PollIntervalSeconds
        $ElapsedSeconds += $PollIntervalSeconds
    }

    Write-StatusMessage "[FAILED]" -ForegroundColor Red
    Write-StatusMessage "The operation may still be running in the background. Check the installation manually." -Verbosity Warning
    return $false
}