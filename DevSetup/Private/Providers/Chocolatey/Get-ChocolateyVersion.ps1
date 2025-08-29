<#
.SYNOPSIS
    Retrieves the version of the installed Chocolatey package manager.

.DESCRIPTION
    This function gets the version information from Chocolatey by executing the 'choco --version' command.
    It includes validation to ensure Chocolatey is installed before attempting to retrieve version information
    and provides comprehensive error handling with appropriate warning messages for various failure scenarios.

.OUTPUTS
    [System.String]
    Returns the Chocolatey version string (trimmed of whitespace) if successful.
    Returns $null if Chocolatey is not installed, version retrieval fails, or an error occurs.

.EXAMPLE
    Get-ChocolateyVersion
    
    Returns the installed Chocolatey version, e.g., "1.4.0"

.EXAMPLE
    $chocoVersion = Get-ChocolateyVersion
    if ($chocoVersion) {
        Write-Host "Chocolatey version: $chocoVersion"
    } else {
        Write-Host "Could not determine Chocolatey version"
    }
    
    Demonstrates capturing and validating the version result.

.EXAMPLE
    $version = Get-ChocolateyVersion
    if ($version -and [version]$version -lt [version]"1.0.0") {
        Write-Warning "Chocolatey version is outdated. Consider upgrading."
    }
    
    Shows version comparison for compatibility checking.

.NOTES
    - Requires Chocolatey to be installed on the system
    - Uses Test-ChocolateyInstalled to verify Chocolatey availability before proceeding
    - Returns $null immediately if Chocolatey is not installed
    - Suppresses stderr output using '2>$null' to avoid console clutter
    - Trims whitespace from the version string for clean output
    - Includes comprehensive try-catch error handling
    - Provides descriptive warning messages for different failure scenarios
    - Does not require administrator privileges

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Version Detection, System Information, Package Manager Utilities
#>

Function Get-ChocolateyVersion {
    [CmdletBinding()]
    Param(
    )

    if (-not (Test-ChocolateyInstalled)) {
        Write-Warning "Chocolatey is not installed. Cannot retrieve version."
        return $null
    }

    try {
        $version = Invoke-Expression "& choco --version" 2>$null
        if ($version) {
            return $version.Trim()
        } else {
            Write-Warning "Failed to retrieve Chocolatey version."
            return $null
        }
    } catch {
        Write-Warning "An error occurred while trying to get Chocolatey version: $_"
        return $null
    }
}