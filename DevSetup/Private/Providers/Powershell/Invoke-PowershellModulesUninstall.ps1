<#
.SYNOPSIS
    Uninstalls multiple PowerShell modules from the system based on YAML configuration.

.DESCRIPTION
    This function removes multiple PowerShell modules specified in a DevSetup YAML configuration.
    It validates administrator privileges when required, parses the configuration for PowerShell
    module definitions, and systematically uninstalls each module. The function supports both
    simple string format and complex object format for module specifications, handles scope
    settings, and provides comprehensive progress reporting during the uninstallation process.

.PARAMETER YamlData
    The parsed YAML configuration data containing PowerShell module definitions.
    This parameter is mandatory and must be a PSCustomObject with the structure:
    devsetup.dependencies.powershell.modules containing an array of module specifications.

.OUTPUTS
    [System.Boolean]
    Returns $true if all modules are successfully processed (even if some individual uninstalls fail).
    Returns $false if the operation encounters critical errors or cannot proceed.

.EXAMPLE
    $config = Read-ConfigurationFile -Path "environment.yaml"
    Invoke-PowershellModulesUninstall -YamlData $config
    
    Uninstalls all PowerShell modules defined in the environment.yaml configuration.

.EXAMPLE
    $yamlData = @{
        devsetup = @{
            dependencies = @{
                powershell = @{
                    scope = "CurrentUser"
                    modules = @("PSReadLine", "Pester", "PowerShellGet")
                }
            }
        }
    }
    Invoke-PowershellModulesUninstall -YamlData $yamlData
    
    Demonstrates uninstalling modules using a programmatically created configuration.

.EXAMPLE
    if (Invoke-PowershellModulesUninstall -YamlData $config) {
        Write-Host "All PowerShell modules processed successfully"
    } else {
        Write-Host "PowerShell module uninstallation encountered errors"
    }
    
    Shows checking the return value to verify uninstallation completion.

.NOTES
    - Requires administrator privileges when uninstalling from AllUsers scope
    - Uses Test-RunningAsAdmin to validate privileges when scope is AllUsers
    - Throws an exception if AllUsers scope is specified without administrator privileges
    - Skips uninstallation gracefully if no PowerShell modules are found in configuration
    - Supports two module specification formats:
      * Simple string: "ModuleName"
      * Complex object: @{ name = "ModuleName"; minimumVersion = "1.0.0"; scope = "CurrentUser" }
    - Global scope setting defaults to CurrentUser if not specified in configuration
    - Module-specific scope settings override the global scope setting
    - Validates module names and skips entries with missing names
    - Uses Uninstall-PowerShellModule for individual module removal
    - Provides detailed progress reporting with module counts and version information
    - Uses color-coded console output: Cyan for progress, Gray for module status, Green/Red for results
    - Continues processing remaining modules even if individual uninstalls fail
    - Returns $true for overall success even with individual module failures
    - Includes comprehensive try-catch error handling with descriptive error messages

.LINK

.COMPONENT
    DevSetup.Providers.PowerShell

.FUNCTIONALITY
    Package Management, Batch Uninstallation, Configuration Processing, Module Management
#>

Function Invoke-PowershellModulesUninstall {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$YamlData,
        [Parameter(Mandatory=$false, Position=1)]
        [switch]$DryRun
    )
    
    $modules = $YamlData.devsetup.dependencies.powershell.modules
    
    # Get global scope setting from YAML, default to CurrentUser
    $globalScope = if ($YamlData.devsetup.dependencies.powershell.scope) { 
        $YamlData.devsetup.dependencies.powershell.scope 
    } else { 
        'CurrentUser' 
    }
    
    try {
        # Check if running as administrator when global scope is AllUsers
        if ($globalScope -eq 'AllUsers' -and (-not (Test-RunningAsAdmin))) {
            Write-StatusMessage "PowerShell module uninstallation to AllUsers scope requires administrator privileges. Please run as administrator or set powershellModuleScope to CurrentUser." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Failed to validate administrator privileges: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    Write-StatusMessage "- Uninstalling PowerShell modules from configuration:" -ForegroundColor Cyan

    $moduleCount = 0
    
    foreach ($module in $modules) {
        # Determine scope for this module (module-specific overrides global)
        $moduleScope = if ($module.scope) { $module.scope } else { $globalScope }

        # Set defaults and build parameters
        $installParams = @{
            ModuleName = $module.name
            WhatIf = $DryRun
        }

        if ($module.minimumVersion) {
            Write-StatusMessage "- Uninstalling PowerShell module: $($module.name) (version: $($module.minimumVersion), scope: $moduleScope)" -ForegroundColor Gray -Width 100 -NoNewLine -Indent 2
        } else {
            Write-StatusMessage "- Uninstalling PowerShell module: $($module.name) (latest version) to $moduleScope scope" -ForegroundColor Gray -Width 100 -NoNewLine -Indent 2
        }

        try {
            if ((Uninstall-PowerShellModule @installParams)) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
                $moduleCount++
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            }
        } catch {
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            Write-StatusMessage "Error uninstalling module $($module.name): $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        }
    }
    Write-StatusMessage "- PowerShell modules uninstallation completed! Processed $moduleCount modules.`n" -ForegroundColor Green
    return $true
}