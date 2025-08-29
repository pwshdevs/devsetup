function Get-DevSetupEnvPath {
    # Get the DevSetup path
    $devSetupPath = Get-DevSetupPath

    # Define the environments path
    $environmentsPath = Join-Path -Path $devSetupPath -ChildPath "environments"

    # Return the environments path
    return $environmentsPath
}