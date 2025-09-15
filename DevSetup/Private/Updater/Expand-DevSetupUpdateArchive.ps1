Function Expand-DevSetupUpdateArchive {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory = $true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath
    )

    if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
        Write-StatusMessage "Archive file not found at path: $Path" -Verbosity Error
        return $false
    }

    try {
        Write-StatusMessage "Expanding archive file from $Path to $DestinationPath" -Verbosity Debug
        Expand-Archive -Path $Path -DestinationPath $DestinationPath -Force
        Write-StatusMessage "Expansion completed successfully." -Verbosity Debug
        return $true
    } catch {
        Write-StatusMessage "Failed to expand archive: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}