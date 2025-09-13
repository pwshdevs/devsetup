<#
.SYNOPSIS
    Exports installed PowerShell modules to a YAML configuration file.

.DESCRIPTION
    This function scans the system for installed PowerShell modules and exports them to a YAML 
    configuration file in DevSetup format. It uses Get-InstalledModule to retrieve comprehensive 
    module information including versions and installation scope. The function intelligently skips 
    core dependency modules defined in the DevSetup manifest and can update existing configuration
    files by merging new modules with existing ones.

.PARAMETER Config
    The path to the YAML configuration file to read from and write to.
    This parameter is mandatory and specifies both the input and output file unless OutFile is specified.

.PARAMETER OutFile
    The path to save the updated YAML configuration.
    Optional parameter that allows saving to a different file than the input Config file.

.PARAMETER DryRun
    Switch parameter that prevents writing to files and displays the resulting configuration to the console.
    Useful for previewing changes before committing them to a file.

.OUTPUTS
    [System.Boolean]
    Returns $true if the export completes successfully or if no modules are found.
    Returns $false if there are errors during the export process.

.EXAMPLE
    Invoke-PowershellModulesExport -Config "environment.yaml"
    
    Exports installed PowerShell modules to the existing environment.yaml configuration file.

.EXAMPLE
    Invoke-PowershellModulesExport -Config "current.yaml" -OutFile "backup.yaml"
    
    Reads from current.yaml and saves the updated configuration with installed modules to backup.yaml.

.EXAMPLE
    Invoke-PowershellModulesExport -Config "dev-env.yaml" -DryRun
    
    Shows what the configuration would look like without actually saving to file.

.NOTES
    - Requires administrator privileges to access all installed modules
    - Uses Get-InstalledModule to retrieve module information from PowerShell Gallery
    - Automatically skips core dependency modules listed in the DevSetup manifest
    - Handles both CurrentUser and AllUsers scope modules using path analysis
    - Merges with existing YAML configuration, preserving other sections
    - Supports both simple string format and complex object format for modules
    - Updates existing modules when versions have changed
    - Converts string entries to hashtable format when additional properties are needed
    - Tracks installation scope (CurrentUser/AllUsers) for each module
    - Creates the devsetup.dependencies.powershell structure if it doesn't exist
    - Provides detailed console output with color-coded status messages
    - Includes comprehensive error handling for module scanning and file operations
    - Preserves existing module properties while updating changed values

.LINK

.COMPONENT
    DevSetup.Providers.PowerShell

.FUNCTIONALITY
    Configuration Export, Module Discovery, YAML Generation
#>

Function Invoke-PowershellModulesExport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Config,
        [switch]$DryRun
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            Write-StatusMessage "This operation requires administrator privileges. Please run as administrator." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Failed to validate administrator privileges: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    # Get installed PowerShell modules
    Write-StatusMessage "- Getting list of installed PowerShell modules..." -ForegroundColor Gray
    try {
        $installedModules = Get-InstalledModule -ErrorAction SilentlyContinue
    } catch {
        Write-StatusMessage "Failed to retrieve installed PowerShell modules: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if (-not $installedModules) {
        Write-StatusMessage "No PowerShell modules found or PowerShellGet is not available." -Verbosity Warning
        return $true
    }

    $powershellModules = @()
        
    # Get core dependency modules to skip from DevSetup manifest
    try {
        $manifest = Get-DevSetupManifest
    } catch {
        Write-StatusMessage "Failed to read DevSetup manifest: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    # Valid formats for core modules in manifest:
    # @('ModuleName1', 'ModuleName2')
    # or
    # @(@{ ModuleName = 'ModuleName1'; ModuleVersion = '1.0.0' }, @{ name = 'ModuleName2'; RequiredVersion = '2.0.0' })
    # In the second version, ModuleVersion and RequiredVersion are mutually exclusive
    # and only one should be used per module entry.

    $coreModulesToSkip = @()
    if ($manifest -and $manifest.RequiredModules) {
        $coreModulesToSkip = $manifest.RequiredModules | ForEach-Object {
            if ($_ -is [string]) {
                $_
            } elseif ($_ -is [hashtable] -and $_.ModuleName) {
                $_.ModuleName
            }
        }
    }
        
    try {
        $InstallPaths = Get-PowershellModuleScopeMap
    } catch {
        Write-StatusMessage "Failed to get PowerShell module scope map: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if(-not $InstallPaths -or $InstallPaths.Count -eq 0) {
        Write-StatusMessage "No PowerShell module install paths found." -Verbosity Warning
        return $true
    }

    try {
        $YamlData = Read-DevSetupEnvFile -Config $Config
    } catch {
        Write-StatusMessage "Failed to read configuration file $Config`: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    foreach ($module in $installedModules) {
        # Skip core dependency modules
        if ($module.Name -in $coreModulesToSkip) {
            Write-StatusMessage "Skipping core dependency module: $($module.Name)" -Verbosity Verbose
            continue
        }
        
        $moduleScope = ($InstallPaths | ForEach-Object {
            if ($module.InstalledLocation -like "$($_.Path)$([System.IO.Path]::DirectorySeparatorChar)*") {
                $_.Scope
            }
        })

        if ($moduleScope -eq "CurrentUser" -or $moduleScope -eq "AllUsers") {
            Write-StatusMessage "Found module: $($module.Name) (version: $($module.Version), scope: $moduleScope)" -Verbosity Debug
            $powershellModules += @{
                name = $module.Name
                version = $module.Version.ToString()
                scope = $moduleScope
            }
        } else {
            Write-StatusMessage "Skipping module with unknown scope: $($module.Name)" -Verbosity Verbose
        }
    }

    Write-StatusMessage "  - Found $($powershellModules.Count) PowerShell modules in CurrentUser or AllUsers scope (excluding core dependencies)" -Verbosity Debug

    # Add modules to YAML data
    foreach ($module in $powershellModules) {
        # Check if module already exists
        $existingModule = $YamlData.devsetup.dependencies.powershell.modules | Where-Object {
            ($_.name -eq $module.name)
        }

        if (-not $existingModule) {
            Write-StatusMessage "- Adding module: $($module.name) ($($module.version), $($module.scope))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
            $YamlData.devsetup.dependencies.powershell.modules += @{
                name = $module.name
                minimumVersion = $module.version
                version = ""
                scope = $module.scope
            }
            Write-StatusMessage "[OK]" -ForegroundColor Green
        } else {
            # Module exists, check if version has changed
            $existingVersion = $null
            if (-not ([string]::IsNullOrEmpty($existingModule.minimumVersion))) {
                $existingVersion = $existingModule.minimumVersion
            } elseif (-not ([string]::IsNullOrEmpty($existingModule.version))) {
                $existingVersion = $existingModule.version
            }

            if ($existingVersion -and $existingVersion -ne $module.version) {
                Write-StatusMessage "- Updating module: $($module.name) ($existingVersion -> $($module.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline

                # Find index and update
                $index = $YamlData.devsetup.dependencies.powershell.modules.IndexOf($existingModule)
                $YamlData.devsetup.dependencies.powershell.modules[$index] = @{
                    name = $module.name
                    minimumVersion = $module.version
                    scope = $module.scope
                    version = ""
                }
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } elseif (-not $existingVersion) {
                Write-StatusMessage "- Updating module version: $($module.name)" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline

                $index = $YamlData.devsetup.dependencies.powershell.modules.IndexOf($existingModule)
                $YamlData.devsetup.dependencies.powershell.modules[$index] = @{
                    name = $module.name
                    minimumVersion = $module.version
                    scope = $module.scope
                    version = ""
                }
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "- Skipping module (No Change): $($module.name) ($($module.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
                Write-StatusMessage "[OK]" -ForegroundColor Green
            }
        }
    }
    
    try {
        Write-StatusMessage "`nSaving configuration to: $Config" -Verbosity Debug
        $YamlData | Update-DevSetupEnvFile -EnvFilePath $Config -WhatIf:$DryRun
        Write-StatusMessage "Configuration saved successfully!" -Verbosity Debug
    }
    catch {
        Write-StatusMessage "Failed to save configuration to $Config`: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    Write-StatusMessage "PowerShell modules conversion completed!" -ForegroundColor Green
    return $true
}