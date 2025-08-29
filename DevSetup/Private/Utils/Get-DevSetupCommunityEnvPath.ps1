function Get-DevSetupCommunityEnvPath {
    # Get the DevSetup path
    $devSetupEnvPath = Get-DevSetupEnvPath

    # Define the environments path
    $communityEnvironmentsPath = Join-Path -Path $devSetupEnvPath -ChildPath "community"

    # Return the environments path
    return $communityEnvironmentsPath
}