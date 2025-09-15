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

    try {
        if (-not (Test-ChocolateyInstalled)) {
            Write-StatusMessage "Chocolatey is not installed. Cannot retrieve version." -Verbosity Warning
            return $null
        }
    } catch {
        Write-StatusMessage "Error checking if Chocolatey is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $chocoCommand = Find-Chocolatey
    } catch {
        Write-StatusMessage "Error locating Chocolatey command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    if(-not $chocoCommand -or [string]::IsNullOrWhiteSpace($chocoCommand)) {
        Write-StatusMessage "Could not find Chocolatey command. Cannot retrieve version." -Verbosity Warning
        return $null
    }

    try {
        if( -not (Test-Path $chocoCommand)) {
            Write-StatusMessage "Chocolatey command path '$chocoCommand' does not exist. Cannot retrieve version." -Verbosity Warning
            return $null
        }
    } catch {
        Write-StatusMessage "Error verifying Chocolatey command path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $version = Invoke-Command -ScriptBlock { & $chocoCommand --version }
    } catch {
        Write-StatusMessage "An error occurred while trying to get Chocolatey version: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }        

    if ($LASTEXITCODE -eq 0 -and $version) {
        return $version
    } else {
        Write-StatusMessage "Failed to retrieve Chocolatey version." -Verbosity Warning
        return $null
    }
}