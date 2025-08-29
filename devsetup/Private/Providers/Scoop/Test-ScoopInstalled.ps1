<#
.SYNOPSIS
    Tests whether Scoop package manager is installed on the system.

.DESCRIPTION
    This function checks if Scoop is installed and available on the system by first attempting to locate
    the scoop command in the PATH, and if not found, checking for Scoop installation files in the default
    user profile directory. It provides a comprehensive check for both standard installations and cases
    where Scoop may not be properly added to the PATH environment variable.

.OUTPUTS
    [System.Boolean]
    Returns $true if Scoop is installed and available, $false otherwise.

.EXAMPLE
    Test-ScoopInstalled
    
    Checks if Scoop is installed on the current system.

.EXAMPLE
    if (Test-ScoopInstalled) {
        Write-Host "Scoop is available"
        # Proceed with Scoop operations
    } else {
        Write-Host "Scoop is not installed"
        # Install Scoop or handle the missing dependency
    }
    
    Demonstrates using the function result to conditionally execute Scoop-dependent code.

.EXAMPLE
    $scoopAvailable = Test-ScoopInstalled
    switch ($scoopAvailable) {
        $true { "Scoop package manager detected" }
        $false { "Scoop package manager not found" }
    }
    
    Shows capturing the boolean result for later use.

.NOTES
    - Performs multiple checks to ensure reliable detection
    - First checks if 'scoop' command is available in PATH using Get-Command
    - Falls back to checking specific file paths in the user profile directory:
      * ~\scoop\shims\scoop.ps1 (PowerShell script)
      * ~\scoop\shims\scoop.cmd (Command batch file)
      * ~\scoop\shims\scoop (Executable)
    - Does not verify that Scoop is functional, only that installation files exist
    - Suppresses errors when checking for the scoop command to avoid console output

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Installation Detection, Environment Validation
#>
Function Test-ScoopInstalled {
    [CmdletBinding()]
    Param ()

    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        return $true
    } else {
        # Check for Scoop in user profile directory
        $scoopPath = Join-Path $env:USERPROFILE "scoop\shims\scoop.ps1"
        if (Test-Path $scoopPath) {
            return $true
        }

        $scoopPath = Join-Path $env:USERPROFILE "scoop\shims\scoop.cmd"
        if (Test-Path $scoopPath) {
            return $true
        }

        $scoopPath = Join-Path $env:USERPROFILE "scoop\shims\scoop"
        if (Test-Path $scoopPath) {
            return $true
        }        
    }
    return $false
}