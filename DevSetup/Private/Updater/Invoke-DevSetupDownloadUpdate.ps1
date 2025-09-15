Function Invoke-DevSetupDownloadUpdate {
    [CmdletBinding(DefaultParameterSetName="Download")]
    [OutputType([string])]
    Param(
        [Parameter(Mandatory = $true, ParameterSetName="Download", Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri
    )

    if(-not ($Uri -match "api.github.com/repos/pwshdevs/devsetup/zipball") -and -not ($Uri -match "github.com/pwshdevs/devsetup/archive")) {
        Write-StatusMessage "Invalid download URL: $Uri" -Verbosity Error
        return $null
    }

    $DestinationPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "devsetup.zip"
    Write-StatusMessage "Downloading update to temporary path: $DestinationPath" -Verbosity Debug
    try {
        Write-StatusMessage "Starting download from $Uri to $DestinationPath" -Verbosity Debug
        Invoke-WebRequest -Uri $Uri -OutFile $DestinationPath
        if( -not (Test-Path $DestinationPath -ErrorAction SilentlyContinue)) {
            Write-StatusMessage "Download completed but file not found at $DestinationPath" -Verbosity Error
            return $null
        }
        Write-StatusMessage "Download completed successfully." -Verbosity Debug
        return $DestinationPath
    } catch {
        Write-StatusMessage "Failed to download update: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }
}