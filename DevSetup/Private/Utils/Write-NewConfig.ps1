Function Write-NewConfig {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$OutFile,
        [Parameter(Mandatory = $false)]
        [switch]$DryRun = $false
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "This operation requires administrator privileges. Please run as administrator."
        }

        $osArchitecture = (Get-HostArchitecture)
        $friendlyPlatform = (Get-HostOperatingSystem)
        $friendlyOsVersion = (Get-HostOperatingSystemVersion)
        $username = "Unknown"
        if((Test-OperatingSystem -Windows)) {
            $username = (Get-EnvironmentVariable USERNAME) 
        } else {
            $username = (Get-EnvironmentVariable USER)
        }
        # Handle versioning and preserve existing config
        $currentVersion = "1.0.0"  # Default version for new files
        $baseConfig = [PSCustomObject][ordered]@{
            devsetup = [PSCustomObject][ordered]@{
                dependencies = [PSCustomObject][ordered]@{
                    chocolatey = @{
                        packages = @()
                    }
                    powershell = @{
                        modules = @()
                        scope = "CurrentUser"
                    }
                    scoop = @{
                        packages = @()
                        buckets = @()
                    }
                }
                commands = @()
                configuration = [ordered]@{
                    description = "Auto-generated development environment configuration"
                    version = $currentVersion
                    createdDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    createdBy = $username
                    os = [PSCustomObject][ordered]@{
                        name = $friendlyPlatform
                        version = $friendlyOsVersion
                        architecture = $osArchitecture
                    }
                    powershell = [PSCustomObject][ordered]@{
                        version = $PSVersionTable.PSVersion.ToString()
                        edition = $PSVersionTable.PSEdition
                    }
                }
            }
        }
        
        if (Test-Path $OutFile) {
            try {
                Write-StatusMessage "- Using existing configuration..." -ForegroundColor Gray
                $existingConfig = Read-DevSetupEnvFile -Config $OutFile
                if ($existingConfig -and $existingConfig.devsetup) {
                    # Preserve existing dependencies
                    if ($existingConfig.devsetup.dependencies) {
                        $baseConfig.devsetup.dependencies = $existingConfig.devsetup.dependencies
                    }
                    
                    # Preserve existing commands
                    if ($existingConfig.devsetup.commands) {
                        $baseConfig.devsetup.commands = $existingConfig.devsetup.commands
                    }
                    
                    # Handle version increment
                    if ($existingConfig.devsetup.configuration -and $existingConfig.devsetup.configuration.version) {
                        $existingVersionString = $existingConfig.devsetup.configuration.version
                        
                        try {
                            # Parse version using System.Version
                            $existingVersion = [System.Version]$existingVersionString
                            $newMinor = $existingVersion.Minor + 1
                            $currentVersion = "$($existingVersion.Major).$newMinor.$($existingVersion.Build)"
                            $baseConfig.devsetup.configuration.version = $currentVersion
                            Write-StatusMessage "- Version: $existingVersionString -> $currentVersion" -ForegroundColor Gray
                        }
                        catch {
                            Write-StatusMessage "- Version: $currentVersion" -Verbosity Warning
                        }
                    } else {
                        Write-StatusMessage "- Version: $currentVersion" -ForegroundColor Gray
                    }
                    
                    # Preserve other configuration fields but update system info
                    if ($existingConfig.devsetup.configuration) {
                        $baseConfig.devsetup.configuration.description = $existingConfig.devsetup.configuration.description
                        $baseConfig.devsetup.configuration.createdBy = $existingConfig.devsetup.configuration.createdBy
                        if ($existingConfig.devsetup.configuration.createdDate) {
                            # Keep original creation date, but we could add a lastModified field
                            $baseConfig.devsetup.configuration.createdDate = $existingConfig.devsetup.configuration.createdDate
                        }
                        if($existingConfig.devsetup.configuration.lastModifiedDate) {
                            $baseConfig.devsetup.configuration.lastModifiedDate = $existingConfig.devsetup.configuration.lastModifiedDate
                        } else {
                            $baseConfig.devsetup.configuration['lastModifiedDate'] = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        }
                    }
                }
            }
            catch {
                Write-StatusMessage "Failed to read existing configuration for merging: $_" -Verbosity Warning
                Write-StatusMessage "- Using new configuration with default version: $currentVersion" -ForegroundColor Gray
            }
        } else {
            Write-StatusMessage "- Using new configuration file, starting with version: $currentVersion" -ForegroundColor Green
        }
        
        try {
            $baseConfig | Update-DevSetupEnvFile -EnvFilePath $OutFile -WhatIf:$DryRun
            Write-StatusMessage "Base configuration file created successfully!" -Verbosity Debug
        }
        catch {
            Write-StatusMessage "Failed to create base configuration file: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }

        if((Test-OperatingSystem -Windows)) {
            # Convert from installed Chocolatey packages
            Write-StatusMessage "`nScanning installed Chocolatey packages..." -ForegroundColor Cyan
            if (-not (Export-InstalledChocolateyPackages -Config $OutFile)) {
                Write-StatusMessage "Failed to convert Chocolatey packages, but continuing..." -Verbosity Warning
            }

            # Convert from installed Scoop packages
            Write-StatusMessage "`nScanning installed Scoop packages..." -ForegroundColor Cyan
            if (-not (Export-InstalledScoopPackages -Config $OutFile)) {
                Write-StatusMessage "Failed to convert Scoop packages, but continuing..." -Verbosity Warning
            }
        } else {
            # Convert from installed Homebrew packages
            Write-StatusMessage "`nScanning installed Homebrew packages..." -ForegroundColor Cyan
            if (-not (Invoke-HomebrewComponentsExport -Config $OutFile -WhatIf:$DryRun)) {
                Write-StatusMessage "Failed to convert Homebrew packages, but continuing..." -Verbosity Warning
            }
        }

        # Convert from installed PowerShell modules
        Write-StatusMessage "`nScanning installed PowerShell modules..." -ForegroundColor Cyan
        if (-not (Invoke-PowershellModulesExport -Config $OutFile -DryRun:$DryRun)) {
            Write-StatusMessage "Failed to convert PowerShell modules, but continuing..." -Verbosity Warning
        }

        ConvertFrom-3rdPartyInstall -Config $OutFile -DryRun:$DryRun | Out-Null

        Write-StatusMessage "`nConfiguration file generation completed!" -ForegroundColor Green
        Write-StatusMessage "- Configuration saved to: $OutFile`n" -ForegroundColor Gray

        Optimize-DevSetupEnvs | Out-Null
        return $true
    }
    catch {
        Write-StatusMessage "Error creating new configuration: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}