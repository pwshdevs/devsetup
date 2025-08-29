<#
.SYNOPSIS
    Tests whether a Scoop package or bucket is installed on the system.

.DESCRIPTION
    Checks if a specified Scoop package or bucket is installed by querying Scoop export data.
    For packages, verifies installation status, version match, and global/local scope.
    For buckets, verifies if the bucket is present in the Scoop configuration.

.PARAMETER Package
    Indicates checking for a package installation.
    Cannot be used with `-Bucket`.

.PARAMETER Bucket
    Indicates checking for a bucket installation.
    Cannot be used with `-Package`.

.PARAMETER Name
    The name of the package or bucket to check.
    Required for all parameter sets.

.PARAMETER Version
    The specific version to check for when validating package installation.
    Optional for package checks; not applicable for bucket checks.

.PARAMETER Global
    Specifies checking for global package installation.
    Optional for package checks; not applicable for bucket checks.

.OUTPUTS
    `[InstalledState]`
    Returns an InstalledState enum value indicating installation status and version match.
    Returns `[InstalledState]::NotInstalled` if not found or Scoop is unavailable.

.EXAMPLE
    Test-ScoopComponentInstalled -Package -Name "git"
    # Checks if the 'git' package is installed via Scoop.

.EXAMPLE
    Test-ScoopComponentInstalled -Package -Name "nodejs" -Version "18.17.0"
    # Checks if the 'nodejs' package version 18.17.0 is installed via Scoop.

.EXAMPLE
    Test-ScoopComponentInstalled -Package -Name "7zip" -Global
    # Checks if the '7zip' package is installed globally via Scoop.

.EXAMPLE
    Test-ScoopComponentInstalled -Bucket -Name "extras"
    # Checks if the 'extras' bucket is added to Scoop.

.NOTES
    **Requirements:**
    - Scoop must be installed.
    - Uses `Read-ScoopCache` for cached export data.

    **Behavior:**
    - Returns `[InstalledState]::NotInstalled` if Scoop is not installed.
    - For packages, checks name, version, and global install status.
    - For buckets, checks if the bucket name exists in the configuration.
    - Returns an InstalledState enum value for detailed status.

    **Error Handling:**
    - Provides debug and warning messages for missing Scoop or cache data.
    - Returns `[InstalledState]::NotInstalled` for missing components.

.LINK
    Read-ScoopCache
    Find-Scoop
    Test-ScoopInstalled

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Package Management, Installation Verification
#>
Function Test-ScoopComponentInstalled {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ParameterSetName='PackageCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionGlobalCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageGlobalCheck')]
        [switch]$Package,
        
        [Parameter(Mandatory=$true, ParameterSetName='BucketCheck')]
        [switch]$Bucket,
        
        [Parameter(Mandatory=$true, ParameterSetName='PackageCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionGlobalCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageGlobalCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='BucketCheck')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionGlobalCheck')]
        [ValidateNotNullOrEmpty()]
        [string]$Version,
        
        [Parameter(Mandatory=$true, ParameterSetName='PackageVersionGlobalCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='PackageGlobalCheck')]
        [switch]$Global
    )

    if(-Not (Test-ScoopInstalled)) {
        return [InstalledState]::NotInstalled
    }

    $scoopComponents = Read-ScoopCache
    if (-not $scoopComponents) {
        return [InstalledState]::NotInstalled
    }
    if ($Package) {
        $packageName = $Name
        [InstalledState]$packageState = [InstalledState]::NotInstalled
        if ($scoopComponents.apps) {
            $scoopComponents.apps | ForEach-Object {
                if ($_.Name -eq $packageName) {
                    $packageState += [InstalledState]::Installed
                    if ($PSBoundParameters.ContainsKey('Version')) {
                        if([Version]$_.Version -eq [Version]$Version) {
                            $packageState += [InstalledState]::RequiredVersionMet
                            $packageState += [InstalledState]::MinimumVersionMet
                        }
                    } else {
                        $packageState += [InstalledState]::RequiredVersionMet
                        $packageState += [InstalledState]::MinimumVersionMet
                    }

                    if($Global) {
                        if ($_.Info -eq "Global Install") {
                            $packageState += [InstalledState]::GlobalVersionMet
                        }
                    } else {
                        $packageState += [InstalledState]::GlobalVersionMet
                    }
                }
            }
        }
        return $packageState
    } elseif ($Bucket) {
        [InstalledState]$bucketState = [InstalledState]::NotInstalled
        if ($scoopComponents.buckets) {
            $scoopComponents.buckets | ForEach-Object {
                if ($_.Name -eq $Name) {
                    Write-Debug "Scoop bucket '$Name' is installed."
                    $bucketState += [InstalledState]::Installed
                    $bucketState += [InstalledState]::MinimumVersionMet
                    $bucketState += [InstalledState]::RequiredVersionMet
                    $bucketState += [InstalledState]::GlobalVersionMet
                }
            }
        }
        return $bucketState
    } 
}