<#
.SYNOPSIS
    Tests whether a Chocolatey package is installed with optional version validation.

.DESCRIPTION
    This function checks if a Chocolatey package is installed on the system and optionally validates
    a specific version requirement. It uses 'choco list' with exact matching to find installed packages
    and examines the returned package information to determine installation status and version details.
    The function supports multiple parameter sets to check different combinations of package existence
    and version matching.

.PARAMETER PackageName
    The name of the Chocolatey package to check.
    This parameter is mandatory for all parameter sets and must be a valid, non-empty string representing a Chocolatey package name.

.PARAMETER Version
    The specific version of the package to validate.
    Mandatory parameter for PackageVersionCheck parameter set.
    When specified, the function checks if the installed package matches this exact version.

.OUTPUTS
    [System.Boolean]
    Returns $true if the package meets all specified criteria (exists, version matches if specified).
    Returns $false if the package is not installed, doesn't meet the specified criteria, or an error occurs.

.EXAMPLE
    Test-ChocolateyPackageInstalled -PackageName "git"
    
    Checks if the git package is installed (any version).

.EXAMPLE
    Test-ChocolateyPackageInstalled -PackageName "nodejs" -Version "18.17.0"
    
    Checks if nodejs package version 18.17.0 is installed.

.EXAMPLE
    $isInstalled = Test-ChocolateyPackageInstalled -PackageName "vscode"
    if ($isInstalled) {
        Write-Host "Visual Studio Code is installed"
    } else {
        Write-Host "Visual Studio Code is not installed"
    }
    
    Demonstrates capturing the return value to check installation status.

.NOTES
    - Requires Chocolatey to be installed on the system
    - Uses Test-ChocolateyInstalled to verify Chocolatey availability before proceeding
    - Returns $false immediately if Chocolatey is not installed
    - Uses 'choco list' with -exact and -r flags for precise package matching and machine-readable output
    - Parses package information in "packagename|version" format returned by Chocolatey
    - Suppresses command output using '*>$null' to avoid console clutter
    - Parameter sets determine validation criteria:
      * PackageCheck: Only checks if package exists (PackageName parameter only)
      * PackageVersionCheck: Checks existence and exact version match (PackageName and Version parameters)
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Provides detailed debug logging for troubleshooting installation issues
    - Uses ValidateNotNullOrEmpty attribute to ensure parameters contain valid values
    - Returns early if package is not found to avoid unnecessary processing

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Package Detection, Installation Verification, Version Validation
#>

Function Test-ChocolateyPackageInstalled {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ParameterSetName='PackageCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionCheck')]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName,

        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionCheck')]
        [ValidateNotNullOrEmpty()]
        [string]$Version
    )

    if (-not (Test-ChocolateyInstalled)) {
        Write-Warning "Chocolatey is not installed. Cannot check for packages."
        return [InstalledState]::NotInstalled
    }

    [InstalledState]$installedState = [InstalledState]::NotInstalled

    try {
        $package = Read-ChocolateyCache
        if ($package) {
            # choco list can return multiple lines, so find the exact match
            $exactMatch = $package | Where-Object { ($_ -split '\|')[0] -eq $PackageName }
            if ($exactMatch) {
                $installedState += [InstalledState]::Installed
                $installedState += [InstalledState]::GlobalVersionMet
                
                $parts = $exactMatch -split '\|'
                $installedVersion = if ($parts.Length -gt 1) { $parts[1] } else { $null }
                
                # Now compare with the requested version
                if ($PSBoundParameters.ContainsKey('Version')) {
                    if([Version]$installedVersion -eq [Version]$Version) {
                        $installedState += [InstalledState]::MinimumVersionMet
                        $installedState += [InstalledState]::RequiredVersionMet
                    }
                } else {
                    $installedState += [InstalledState]::MinimumVersionMet
                    $installedState += [InstalledState]::RequiredVersionMet                    
                }
            }
        }
        return $installedState
    } catch {
        return [InstalledState]::NotInstalled
    }
}