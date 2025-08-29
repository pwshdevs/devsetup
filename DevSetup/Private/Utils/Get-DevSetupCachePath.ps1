<#
.SYNOPSIS
    Gets the DevSetup cache directory path and ensures it exists.

.DESCRIPTION
    This function retrieves the cache directory path for the DevSetup module. The cache directory
    is located at ".cache" within the main DevSetup directory and is used to store temporary files,
    downloaded configurations, and other cached data. The function automatically creates the cache
    directory if it doesn't exist, ensuring it's always available for use.

.OUTPUTS
    [System.String]
    Returns the full path to the DevSetup cache directory.

.EXAMPLE
    Get-DevSetupCachePath
    
    Returns the path to the DevSetup cache directory, e.g., "C:\Users\Username\.devsetup\.cache"

.EXAMPLE
    $cachePath = Get-DevSetupCachePath
    $tempFile = Join-Path $cachePath "temp-config.yaml"
    
    Gets the cache path and creates a path for a temporary file within it.

.EXAMPLE
    $cacheDir = Get-DevSetupCachePath
    Get-ChildItem $cacheDir
    
    Gets the cache directory and lists its contents.

.NOTES
    - Uses Get-DevSetupPath to determine the base DevSetup directory
    - Creates the cache directory (.cache) if it doesn't exist
    - Returns the full path as a string for use in other functions
    - The cache directory is hidden (starts with a dot) on Unix-like systems
    - Suppresses output from New-Item using Out-Null for clean execution
    - Ensures the cache directory is always available for DevSetup operations

.LINK

.COMPONENT
    DevSetup.Utils

.FUNCTIONALITY
    Path Management, Directory Creation, Cache Management
#>

Function Get-DevSetupCachePath {
    $devSetupPath = Get-DevSetupPath

    # Define the cache path
    $cachePath = Join-Path -Path $devSetupPath -ChildPath ".cache"

    if (-not (Test-Path -Path $cachePath)) {
        New-Item -ItemType Directory -Path $cachePath | Out-Null
    }

    return $cachePath
}