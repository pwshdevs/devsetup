<#
.SYNOPSIS
    Tests whether Chocolatey package manager is installed on the system.

.DESCRIPTION
    This function checks if Chocolatey is installed and available by attempting to locate the 'choco' command.
    It uses Get-Command to verify that the Chocolatey executable is accessible in the system PATH.
    The function provides a warning message when Chocolatey is not found and returns a boolean result
    indicating the installation status.

.OUTPUTS
    [System.Boolean]
    Returns $true if Chocolatey is installed and the 'choco' command is available.
    Returns $false if Chocolatey is not installed or the 'choco' command cannot be found.

.EXAMPLE
    Test-ChocolateyInstalled
    
    Checks if Chocolatey is installed on the system.

.EXAMPLE
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is available"
        # Proceed with Chocolatey operations
    } else {
        Write-Host "Chocolatey is not installed"
        # Handle missing Chocolatey
    }
    
    Demonstrates conditional logic based on Chocolatey availability.

.EXAMPLE
    $hasChocolatey = Test-ChocolateyInstalled
    if (-not $hasChocolatey) {
        Install-Chocolatey
    }
    
    Shows using the function result to trigger Chocolatey installation if needed.

.NOTES
    - Uses Get-Command with -ErrorAction SilentlyContinue to suppress errors when 'choco' is not found
    - Provides a descriptive warning message when Chocolatey is not installed
    - Does not require administrator privileges to check installation status
    - Checks for command availability rather than file system presence for more reliable detection
    - Used as a prerequisite check by other Chocolatey-related functions in the DevSetup module

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Installation Verification, Prerequisites Check, System Detection
#>

Function Test-ChocolateyInstalled {
    [CmdletBinding()]
    Param()

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Warning "Chocolatey is not installed. Cannot check for Chocolatey packages."
        return $false
    }
    return $true
}