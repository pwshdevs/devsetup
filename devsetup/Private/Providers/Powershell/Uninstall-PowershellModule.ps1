<#
.SYNOPSIS
    Uninstalls a PowerShell module from the system.

.DESCRIPTION
    This function removes a PowerShell module from the system by first removing it from the current session
    using Remove-Module, then uninstalling it completely using Uninstall-Module. The function includes
    validation to check if the module is installed before attempting removal, validates administrator 
    privileges for AllUsers scope modules, and provides comprehensive error handling throughout the 
    uninstallation process.

.PARAMETER ModuleName
    The name of the PowerShell module to uninstall.
    This parameter is mandatory and must be a valid string representing an installed PowerShell module name.

.OUTPUTS
    [System.Boolean]
    Returns $true if the module was successfully uninstalled or was not installed.
    Returns $false if the uninstallation failed or insufficient privileges for AllUsers modules.

.EXAMPLE
    Uninstall-PowershellModule -ModuleName "posh-git"
    
    Uninstalls the posh-git module from the system.

.EXAMPLE
    $result = Uninstall-PowershellModule -ModuleName "PSReadLine"
    if ($result) {
        Write-Host "PSReadLine module removed successfully"
    } else {
        Write-Host "Failed to remove PSReadLine module"
    }
    
    Demonstrates capturing the return value to check uninstallation success.

.EXAMPLE
    @("Module1", "Module2", "Module3") | ForEach-Object {
        Uninstall-PowershellModule -ModuleName $_
    }
    
    Shows bulk uninstallation of multiple modules.

.NOTES
    - Uses Test-PowershellModuleInstalled to verify module existence before attempting removal
    - Returns $true if module is not installed (considered successful since goal is achieved)
    - Validates administrator privileges for AllUsers scope modules using Test-RunningAsAdmin
    - Returns $false immediately if AllUsers module requires elevation but session is not elevated
    - Performs two-step removal process:
      1. Remove-Module: Removes from current PowerShell session (with -Force flag)
      2. Uninstall-Module: Completely removes from system (with -Force flag)
    - Uses -ErrorAction Stop for proper exception handling
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Provides detailed debug logging for troubleshooting uninstallation issues
    - Uses Write-Warning for non-critical issues (module not found, privilege issues)
    - Uses Write-Error for actual uninstallation failures

.LINK

.COMPONENT
    DevSetup.Providers.PowerShell

.FUNCTIONALITY
    Module Management, Package Removal, System Cleanup
#>

Function Uninstall-PowershellModule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $ModuleName
    )

    $installedState = Test-PowershellModuleInstalled -ModuleName $ModuleName
    if ($installedState -eq [InstalledState]::NotInstalled) {
        Write-Warning "PowerShell module '$ModuleName' is not installed. No action taken."
        return $true
    }

    $installedState = Test-PowershellModuleInstalled -ModuleName $ModuleName -Scope 'AllUsers'
    if ($installedState.HasFlag([InstalledState]::Pass) -and (-not (Test-RunningAsAdmin))) {
        Write-Warning "PowerShell module '$ModuleName' is installed for AllUsers but current session is not elevated. Cannot uninstall."
        return $false
    }

    try {
        Write-Debug "Uninstalling PowerShell module '$ModuleName'..."
        Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
        Uninstall-Module -Name $ModuleName -Force -ErrorAction Stop
        Write-Debug "PowerShell module '$ModuleName' uninstalled successfully."
        $installedState = Test-PowershellModuleInstalled -ModuleName $ModuleName
        return ($installedState -eq [InstalledState]::NotInstalled)
    } catch {
        Write-Error "Failed to uninstall PowerShell module '$ModuleName': $_"
        return $false
    }
}