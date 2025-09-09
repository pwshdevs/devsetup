Function Get-DevSetupPath {
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    # Get user's home directory
    if(Test-OperatingSystem -Windows) {
        $homeDirectory = Get-EnvironmentVariable USERPROFILE
    } elseif (Test-OperatingSystem -Linux) {
        $homeDirectory = Get-EnvironmentVariable HOME
    } elseif (Test-OperatingSystem -MacOS) {
        $homeDirectory = Get-EnvironmentVariable HOME
    }

    # Define .devsetup folder path
    try {
        $devSetupPath = Join-Path -Path $homeDirectory -ChildPath "devsetup"
        return $devSetupPath
    } catch {
        Write-StatusMessage "Failed to get DevSetup path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }
}