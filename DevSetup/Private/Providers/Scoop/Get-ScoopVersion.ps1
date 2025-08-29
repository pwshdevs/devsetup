<#
.SYNOPSIS
    Retrieves the version information for the installed Scoop package manager.

.DESCRIPTION
    This function queries the installed Scoop package manager to determine its version. It uses the 'scoop --version'
    command and parses the output to extract version information. The function handles both tagged releases 
    (e.g., "v0.5.3") and development builds identified by commit hashes. Output is completely suppressed during
    execution to avoid console clutter.

.OUTPUTS
    [System.String]
    Returns the Scoop version string if found, "installed" if version cannot be determined but Scoop is present,
    or $null if Scoop is not installed or cannot be found.

.EXAMPLE
    Get-ScoopVersion
    
    Retrieves the version of the currently installed Scoop package manager.

.EXAMPLE
    $version = Get-ScoopVersion
    if ($version) {
        Write-Host "Scoop version: $version"
    } else {
        Write-Host "Scoop is not installed"
    }
    
    Demonstrates checking if Scoop is installed and displaying its version.

.EXAMPLE
    switch (Get-ScoopVersion) {
        $null { "Scoop not found" }
        "installed" { "Scoop is installed but version unknown" }
        default { "Scoop version: $_" }
    }
    
    Shows handling different return scenarios from the function.

.NOTES
    - Requires Scoop to be installed and accessible via Find-Scoop function
    - Uses Start-Process with output redirection to completely suppress console output
    - Parses version output with two fallback strategies:
      1. Tagged release format: "v0.5.3 - Released at..."
      2. Development build format: "ebd8c036 (HEAD -> master..."
    - Creates temporary files for output capture which are automatically cleaned up
    - Returns "installed" if Scoop responds but version cannot be parsed
    - Returns $null if Scoop is not found or accessible
    - Handles errors gracefully without stopping execution

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Version Detection, System Information
#>
Function Get-ScoopVersion {
    [CmdletBinding()]
    Param ()

    $scoopVersion = $null
    $scoopCommand = Find-Scoop
    if ($scoopCommand) {
        try {
            # Use Start-Process with PowerShell to completely suppress console output
            # Scoop is a PowerShell script, so we always need to run it through PowerShell
            $command = "& '$scoopCommand' --version"

            $scoopVersionOutput = Invoke-Expression $command 6>$null

            if ($scoopVersionOutput) {
                # Try to find version tag format first (e.g., "v0.5.3 - Released at...")
                $outputLines = $scoopVersionOutput -split "`n" | Where-Object { $_ -and $_.Trim() }
                $versionLine = $outputLines | Where-Object { $_ -match "[0-9]+\-?[0-9]?\.[0-9]+\.[0-9]+" } | Select-Object -First 1
                
                if ($versionLine) {
                    if ($versionLine -match "([0-9]+\-?[0-9]?\.[0-9]+\.[0-9]+)") {
                        $scoopVersion = $matches[1]
                    }
                } else {
                    # Fallback to commit hash format (e.g., "ebd8c036 (HEAD -> master...")
                    $hashLine = $outputLines | Where-Object { $_ -match "^[a-f0-9]{8,12}" } | Select-Object -First 1
                    if ($hashLine) {
                        $hashParts = $hashLine.Split(' ')
                        if ($hashParts -and $hashParts.Length -gt 0) {
                            $scoopVersion = $hashParts[0]  # Get just the commit hash
                        }
                    } else {
                        $scoopVersion = "installed"
                    }
                }
            }
        } catch {
            Write-Warning "Could not get Scoop version: $_"
            $scoopVersion = "installed"
        }
        return $scoopVersion
    } else {
        return $null
    }
}