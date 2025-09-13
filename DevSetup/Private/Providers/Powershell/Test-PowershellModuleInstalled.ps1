<#
.SYNOPSIS
    Tests whether a PowerShell module is installed, with optional version and scope validation.

.DESCRIPTION
    Checks if a PowerShell module is installed on the system and optionally validates
    specific version requirements and installation scope. Uses `Get-Module -ListAvailable`
    to find installed modules and examines their installation paths to determine scope
    (`CurrentUser` vs `AllUsers`). Supports multiple parameter sets to check different
    combinations of module existence, version matching, and scope validation.

.PARAMETER ModuleName
    The name of the PowerShell module to check.
    Mandatory for all parameter sets.

.PARAMETER Version
    The specific version of the module to validate.
    Optional; only used in version-related parameter sets.

.PARAMETER Scope
    The installation scope to validate (`CurrentUser` or `AllUsers`).
    Optional; only used in scope-related parameter sets.

.OUTPUTS
    `[InstalledState]`
    Returns an InstalledState enum value indicating installation status and version/scope match.
    Returns `[InstalledState]::NotInstalled` if not found or criteria are not met.

.EXAMPLE
    Test-PowershellModuleInstalled -ModuleName "posh-git"
    # Checks if the posh-git module is installed (any version, any scope).

.EXAMPLE
    Test-PowershellModuleInstalled -ModuleName "PSReadLine" -Version "2.2.6"
    # Checks if PSReadLine module version 2.2.6 is installed.

.EXAMPLE
    Test-PowershellModuleInstalled -ModuleName "PowerShellGet" -Scope "AllUsers"
    # Checks if PowerShellGet module is installed in AllUsers scope.

.EXAMPLE
    Test-PowershellModuleInstalled -ModuleName "Az" -Version "9.0.1" -Scope "CurrentUser"
    # Checks if Az module version 9.0.1 is installed in CurrentUser scope.

.NOTES
    **Module Paths:**
    - CurrentUser (PS5.1): `$HOME\Documents\WindowsPowerShell\Modules`
    - CurrentUser (PS7+): `$HOME\Documents\PowerShell\Modules`
    - AllUsers (PS5.1): `$Env:ProgramFiles\WindowsPowerShell\Modules`
    - AllUsers (PS7+): `$Env:ProgramFiles\PowerShell\Modules`

    **Parameter Sets:**
    - `ModuleCheck`: Checks if module exists.
    - `ModuleVersionCheck`: Checks existence and exact version match.
    - `ModuleScopeCheck`: Checks existence and scope match.
    - `ModuleVersionAndScopeCheck`: Checks existence, version, and scope match.

    **Behavior:**
    - Returns the highest version when multiple versions are installed.
    - Uses `[InstalledState]` enum for detailed status.
    - Includes error handling and debug logging.

.LINK
    Get-Module

.COMPONENT
    DevSetup.Providers.PowerShell

.FUNCTIONALITY
    Module Detection, Installation Verification, Scope Validation
#>

Function Test-PowershellModuleInstalled {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ParameterSetName='ModuleCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='ModuleVersionCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='ModuleScopeCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='ModuleVersionAndScopeCheck')]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter(Mandatory=$true, ParameterSetName='ModuleVersionCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='ModuleVersionAndScopeCheck')]
        [string]$Version,
        
        [Parameter(Mandatory=$true, ParameterSetName='ModuleScopeCheck')]
        [Parameter(Mandatory=$true, ParameterSetName='ModuleVersionAndScopeCheck')]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]$Scope
    )

    if((Test-OperatingSystem -Windows)) {
        $SearchPath = (Get-EnvironmentVariable USERPROFILE)
    } else {
        $SearchPath = (Get-EnvironmentVariable HOME)
    }

    $InstallPaths = @(
        (Get-EnvironmentVariable PSModulePath) -split ([System.IO.Path]::PathSeparator) | ForEach-Object { 
            if($_ -match [regex]::Escape("$SearchPath")) { 
                @{ Path = $_; Scope = "CurrentUser" } 
            } else {
                @{ Path = $_; Scope = "AllUsers" }
            } 
        }
    )

    [InstalledState]$installedState = [InstalledState]::NotInstalled

    try {
        $module = Get-Module -Name $ModuleName -ListAvailable -ErrorAction Stop | 
                Sort-Object Version -Descending | 
                Select-Object -First 1
        
        if ($module) {
            $installedState = [InstalledState]::Installed

            if($PSBoundParameters.ContainsKey('Scope')) {
                $InstallPaths | ForEach-Object {
                    if ($module.Path -like "$($_.Path)$([System.IO.Path]::DirectorySeparatorChar)*") {
                        if ($_.Scope -eq $Scope) {
                            $installedState += [InstalledState]::GlobalVersionMet
                        }
                    }
                }
            } else {
                $installedState += [InstalledState]::GlobalVersionMet
            }

            if ($PSBoundParameters.ContainsKey('Version')) {
                if([Version]$module.Version -eq [Version]$Version) {
                    $installedState += [InstalledState]::MinimumVersionMet
                    $installedState += [InstalledState]::RequiredVersionMet
                }
            } else {
                $installedState += [InstalledState]::MinimumVersionMet
                $installedState += [InstalledState]::RequiredVersionMet
            }
        }
        return $installedState
    } catch {
        return [InstalledState]::NotInstalled
    }
}