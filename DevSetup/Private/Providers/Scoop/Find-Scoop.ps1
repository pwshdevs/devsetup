<#
.SYNOPSIS
    Locates the Scoop package manager executable on the system.

.DESCRIPTION
    This function searches for the Scoop package manager executable using multiple detection methods.
    It first attempts to find 'scoop' in the system PATH, and if not found, searches for Scoop
    installation files in the default user profile directory. The function returns the appropriate
    command or file path that can be used to execute Scoop operations.

.OUTPUTS
    [System.String]
    Returns "scoop" if found in PATH, the full file path to the Scoop executable if found in the user profile,
    or $null if Scoop cannot be located.

.EXAMPLE
    Find-Scoop
    
    Locates the Scoop executable on the current system.

.EXAMPLE
    $scoopCommand = Find-Scoop
    if ($scoopCommand) {
        & $scoopCommand list
    } else {
        Write-Warning "Scoop not found"
    }
    
    Demonstrates using the returned command to execute Scoop operations.

.EXAMPLE
    switch (Find-Scoop) {
        "scoop" { "Scoop found in PATH" }
        { $_ -like "*scoop.ps1" } { "Found PowerShell script: $_" }
        { $_ -like "*scoop.cmd" } { "Found batch file: $_" }
        { $_ -like "*scoop" } { "Found executable: $_" }
        $null { "Scoop not found" }
    }
    
    Shows handling different types of Scoop installations.

.NOTES
    - Performs multiple checks to locate Scoop installations:
      1. Checks if 'scoop' command is available in PATH using Get-Command
      2. Searches for ~\scoop\shims\scoop.ps1 (PowerShell script)
      3. Searches for ~\scoop\shims\scoop.cmd (Command batch file)
      4. Searches for ~\scoop\shims\scoop (Executable)
    - Returns the most accessible form first (PATH command before file paths)
    - Suppresses errors when checking for the scoop command to avoid console output
    - The returned value can be used directly with the call operator (&) or Invoke-Expression
    - Does not verify that the found executable is functional, only that it exists

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Executable Location, Path Resolution
#>
Function Find-Scoop {
    [CmdletBinding()]
    Param ()

    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        return "scoop"
    } else {
        # Check for Scoop in user profile directory
        $userProfilePath = (Get-EnvironmentVariable USERPROFILE)
        $scoopPath = Join-Path $userProfilePath "scoop\shims\scoop.ps1"
        if (Test-Path $scoopPath) {
            return $scoopPath
        }

        $scoopPath = Join-Path $userProfilePath "scoop\shims\scoop.cmd"
        if (Test-Path $scoopPath) {
            return $scoopPath
        }

        $scoopPath = Join-Path $userProfilePath "scoop\shims\scoop"
        if (Test-Path $scoopPath) {
            return $scoopPath
        }        
    }
    return $null
}