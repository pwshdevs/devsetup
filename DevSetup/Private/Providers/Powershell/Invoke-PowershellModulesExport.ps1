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
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,
        [switch]$DryRun
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "This operation requires administrator privileges. Please run as administrator."
        }

        # Get installed PowerShell modules
        Write-StatusMessage "- Getting list of installed PowerShell modules..." -ForegroundColor Gray
        $installedModules = Get-InstalledModule -ErrorAction SilentlyContinue

        if (-not $installedModules) {
            Write-StatusMessage "No PowerShell modules found or PowerShellGet is not available." -Verbosity Warning
            return $true
        }

        $powershellModules = @()
        
        # Get core dependency modules to skip from DevSetup manifest
        $manifest = Get-DevSetupManifest
        $coreModulesToSkip = @()
        if ($manifest -and $manifest.RequiredModules) {
            $coreModulesToSkip = $manifest.RequiredModules | ForEach-Object {
                if ($_ -is [string]) {
                    $_
                } elseif ($_ -is [hashtable] -and $_.ModuleName) {
                    $_.ModuleName
                } elseif ($_ -is [hashtable] -and $_.name) {
                    $_.name
                }
            }
        }
        
        foreach ($module in $installedModules) {
            # Skip core dependency modules
            if ($module.Name -in $coreModulesToSkip) {
                Write-StatusMessage "Skipping core dependency module: $($module.Name)" -Verbosity Verbose
                continue
            }
            
            # Get module scope information
            $moduleInfo = Get-Module -Name $module.Name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
            
            # Check if module is in CurrentUser or AllUsers scope
            $modulePath = $moduleInfo.ModuleBase
            $scope = "Unknown"
            
            if ($modulePath -like "*\WindowsPowerShell\Modules\*" -or $modulePath -like "*\PowerShell\Modules\*") {
                if ($modulePath -like "*$env:USERPROFILE*") {
                    $scope = "CurrentUser"
                } else {
                    $scope = "AllUsers"
                }
            }
            
            if ($scope -eq "CurrentUser" -or $scope -eq "AllUsers") {
                Write-StatusMessage "Found module: $($module.Name) (version: $($module.Version), scope: $scope)" -Verbosity Debug
                $powershellModules += @{
                    name = $module.Name
                    version = $module.Version.ToString()
                    scope = $scope
                }
            } else {
                Write-StatusMessage "Skipping module with unknown scope: $($module.Name)" -Verbosity Verbose
            }
        }

        Write-StatusMessage "  - Found $($powershellModules.Count) PowerShell modules in CurrentUser or AllUsers scope (excluding core dependencies)" -Verbosity Debug

        # Read existing YAML configuration
        $YamlData = Read-DevSetupEnvFile -Config $Config

        # Ensure powershellModules section exists
        if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
        if (-not $YamlData.devsetup.dependencies) { $YamlData.devsetup.dependencies = @{} }
        if (-not $YamlData.devsetup.dependencies.powershell) { $YamlData.devsetup.dependencies.powershell = @{} }
        if (-not $YamlData.devsetup.dependencies.powershell.modules) { $YamlData.devsetup.dependencies.powershell.modules = @() }

        # Add modules to YAML data
        foreach ($module in $powershellModules) {
            # Check if module already exists
            $existingModule = $YamlData.devsetup.dependencies.powershell.modules | Where-Object {
                ($_ -is [string] -and $_ -eq $module.name) -or
                ($_.name -eq $module.name)
            }

            if (-not $existingModule) {
                Write-StatusMessage "  - Adding module: $($module.name) ($($module.version), $($module.scope))" -ForegroundColor Gray
                $YamlData.devsetup.dependencies.powershell.modules += @{
                    name = $module.name
                    minimumVersion = $module.version
                    scope = $module.scope
                }
            } else {
                # Module exists, check if version has changed
                $existingVersion = $null
                if ((-not ($existingModule -is [string])) -and $existingModule.minimumVersion) {
                    $existingVersion = $existingModule.minimumVersion
                } elseif ((-not ($existingModule -is [string])) -and $existingModule.version) {
                    $existingVersion = $existingModule.version
                }

                if ($existingVersion -and $existingVersion -ne $module.version) {
                    Write-StatusMessage "    - Updating module: $($module.name) ($existingVersion -> $($module.version))" -ForegroundColor Gray

                    # Find index and update
                    $index = $YamlData.devsetup.dependencies.powershell.modules.IndexOf($existingModule)

                    # Preserve existing module structure but update version
                    if ($existingModule -is [string]) {
                        # Convert string to hashtable with version
                        $YamlData.devsetup.dependencies.powershell.modules[$index] = @{
                            name = $module.name
                            minimumVersion = $module.version
                            scope = $module.scope
                        }
                    } else {
                        # Update existing hashtable
                        $YamlData.devsetup.dependencies.powershell.modules[$index].minimumVersion = $module.version
                        if (-not $existingModule.scope) {
                            $YamlData.devsetup.dependencies.powershell.modules[$index].scope = $module.scope
                        }
                    }
                } elseif (-not $existingVersion) {
                    Write-StatusMessage "  - Updating module version: $($module.name)" -ForegroundColor Gray

                    # Find index and add version
                    $index = $YamlData.devsetup.dependencies.powershell.modules.IndexOf($existingModule)

                    if ($existingModule -is [string]) {
                        # Convert string to hashtable with version
                        $YamlData.devsetup.dependencies.powershell.modules[$index] = @{
                            name = $module.name
                            minimumVersion = $module.version
                            scope = $module.scope
                        }
                    } else {
                        # Add version to existing hashtable
                        $YamlData.devsetup.dependencies.powershell.modules[$index].minimumVersion = $module.version
                        if (-not $existingModule.scope) {
                            $YamlData.devsetup.dependencies.powershell.modules[$index].scope = $module.scope
                        }
                    }
                } else {
                    Write-StatusMessage "  - Skipping module (No Change): $($module.name) ($($module.version))" -ForegroundColor Gray
                }
            }
        }

        # Handle output based on parameters
        # Determine output file
        $outputFile = if ($OutFile) { $OutFile } else { $Config }
        
        try {
            Write-StatusMessage "`nSaving configuration to: $outputFile" -Verbosity Debug
            $YamlData | Update-DevSetupEnvFile -EnvFilePath $Config -WhatIf:$DryRun
            Write-StatusMessage "Configuration saved successfully!" -Verbosity Debug
        }
        catch {
            Write-StatusMessage "Failed to save configuration to $outputFile`: $_" -Verbosity Error
            return $false
        }

        Write-StatusMessage "PowerShell modules conversion completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-StatusMessage "Error converting PowerShell modules: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}