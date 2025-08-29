function Get-DevSetupLocalEnvPath {
    # Get the DevSetup path
    $devSetupEnvPath = Get-DevSetupEnvPath

    # Define the environments path
    $localEnvironmentsPath = Join-Path -Path $devSetupEnvPath -ChildPath "local"

    # Return the environments path
    return $localEnvironmentsPath
}