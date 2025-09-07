<#
.SYNOPSIS
    Installs PowerShell modules from YAML configuration data.

.DESCRIPTION
    This function processes YAML configuration data to install PowerShell modules using Install-PowerShellModule.
    It supports both simple string formats and complex object formats for modules, allowing for detailed 
    configuration including versions, installation scope, and module-specific parameters. The function validates
    administrator privileges when AllUsers scope is specified and provides comprehensive error handling and 
    progress reporting throughout the installation process.

.PARAMETER YamlData
    The YAML configuration data containing PowerShell module definitions.
    This parameter is mandatory and must be a PSCustomObject with the structure:
    devsetup.dependencies.powershell.modules and optionally devsetup.dependencies.powershell.scope

.OUTPUTS
    [System.Boolean]
    Returns $true if installation completes successfully (even if individual modules fail).
    Returns $false if configuration is invalid or critical errors occur.

.EXAMPLE
    $yamlData = Get-Content "config.yaml" | ConvertFrom-Yaml
    Install-PowershellModules -YamlData $yamlData
    
    Installs PowerShell modules from a YAML configuration file.

.EXAMPLE
    $yamlData = @{
        devsetup = @{
            dependencies = @{
                powershell = @{
                    scope = "CurrentUser"
                    modules = @(
                        "posh-git",
                        @{
                            name = "PSReadLine"
                            minimumVersion = "2.2.6"
                        },
                        @{
                            name = "PowerShellGet"
                            scope = "AllUsers"
                            force = $true
                            allowClobber = $false
                        }
                    )
                }
            }
        }
    }
    Install-PowershellModules -YamlData $yamlData
    
    Demonstrates the PSCustomObject structure and installs the configured modules.

.NOTES
    - Requires the YAML configuration to have devsetup.dependencies.powershell.modules structure
    - Returns $false immediately if PowerShell modules configuration is missing or invalid
    - Supports global scope setting with module-specific overrides
    - Default scope is 'CurrentUser' if not specified
    - Validates administrator privileges when AllUsers scope is requested
    - Supports both string and object formats for module definitions
    - Module object format supports: name (required), minimumVersion (optional), scope (optional), force (optional), allowClobber (optional)
    - Skips empty or invalid entries in the configuration without stopping execution
    - Uses Install-PowerShellModule function for actual installation
    - Provides detailed progress reporting with color-coded status messages
    - Individual installation failures do not stop the overall process
    - Tracks and reports installation counts for all processed modules
    - Uses parameter splatting for reliable module installation

.LINK

.COMPONENT
    DevSetup.Providers.PowerShell

.FUNCTIONALITY
    Bulk Installation, Configuration Processing, Module Management
#>

Function Install-PowershellModule {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$YamlData
    )
    
    try {
        Write-StatusMessage "- Installing PowerShell modules from configuration:" -ForegroundColor Cyan
        # Check if PowerShell modules dependencies exist
        if (-not $YamlData -or -not $YamlData.devsetup -or -not $YamlData.devsetup.dependencies -or -not $YamlData.devsetup.dependencies.powershell -or -not $YamlData.devsetup.dependencies.powershell.modules) {
            Write-Debug "PowerShell modules not found in YAML configuration. Skipping installation."
            Write-StatusMessage "- PowerShell modules installation completed! Processed 0 modules." -ForegroundColor Green
            Write-Host ""
            return $false
        }
        
        $modules = $YamlData.devsetup.dependencies.powershell.modules
        
        # Get global scope setting from YAML, default to CurrentUser
        $globalScope = 'AllUsers'
        if ($YamlData.devsetup.dependencies.powershell.scope) { 
            $globalScope = $YamlData.devsetup.dependencies.powershell.scope 
        }
        
        # Check if running as administrator when global scope is AllUsers
        if ($globalScope -eq 'AllUsers' -and (-not (Test-RunningAsAdmin))) {
            throw "PowerShell module installation to AllUsers scope requires administrator privileges. Please run as administrator or set powershellModuleScope to CurrentUser."
        }
        

        $moduleCount = 0
        
        foreach ($module in $modules) {
            if (-not $module) { continue }
            
            $moduleCount++
            
            # Normalize module to object format
            if ($module -is [string]) {
                $moduleObj = @{ name = $module }
            } else {
                $moduleObj = $module
            }
            
            # Validate module name
            if ([string]::IsNullOrEmpty($moduleObj.name)) {
                Write-Warning "Module entry #$moduleCount has no name specified, skipping"
                continue
            }
            
            # Determine scope for this module (module-specific overrides global)
            $moduleScope = if ($moduleObj.scope) { $moduleObj.scope } else { $globalScope }
            
            # Set defaults and build parameters
            $installParams = @{
                ModuleName = $moduleObj.name
                Force = if ($moduleObj.force -is [bool]) { $moduleObj.force } else { $true }
                AllowClobber = if ($moduleObj.allowClobber -is [bool]) { $moduleObj.allowClobber } else { $true }
                Scope = $moduleScope
            }
            
            if ($moduleObj.minimumVersion) {
                $installParams.Version = $moduleObj.minimumVersion
                Write-StatusMessage "- Installing PowerShell module: $($moduleObj.name) (version: $($moduleObj.minimumVersion), scope: $moduleScope)" -ForegroundColor Gray -Width 112 -NoNewLine -Indent 2
            } else {
                Write-StatusMessage "- Installing PowerShell module: $($moduleObj.name) (latest version) to $moduleScope scope" -ForegroundColor Gray -Width 112 -NoNewLine -Indent 2
            }
            
            if ((Install-PowerShellModule @installParams)) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            }
        }
        Write-StatusMessage "- PowerShell modules installation completed! Processed $moduleCount modules." -ForegroundColor Green
        Write-Host ""
        return $true
    }
    catch {
        Write-Error "Error installing PowerShell modules: $_"
        return $false
    }
}