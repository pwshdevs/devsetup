Function Get-DevSetupPath {
    # Get user's home directory
    if(Test-OperatingSystem -Windows) {
        $homeDirectory = Get-EnvironmentVariable USERPROFILE
    } elseif (Test-OperatingSystem -Linux) {
        $homeDirectory = Get-EnvironmentVariable HOME
    } elseif (Test-OperatingSystem -MacOS) {
        $homeDirectory = Get-EnvironmentVariable HOME
    }

    # Define .devsetup folder path
    $devSetupPath = Join-Path -Path $homeDirectory -ChildPath "devsetup"
    return $devSetupPath
}