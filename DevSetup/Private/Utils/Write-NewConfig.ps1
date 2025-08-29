Function Write-NewConfig {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$OutFile
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "This operation requires administrator privileges. Please run as administrator."
        }

        # Create base config file
        #Write-Host "Creating base configuration file: $OutFile" -ForegroundColor Cyan
        
        # Get OS information in a PowerShell 5.1 compatible way
        $platform = [System.Environment]::OSVersion.Platform.ToString()
        $osArchitecture = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        
        # Make platform more user-friendly
        $friendlyPlatform = switch ($platform) {
            "Win32NT" { "Windows" }
            "Unix" { 
                # Check if it's macOS or Linux in a PS 5.1 compatible way
                $uname = ""
                try {
                    $uname = (& uname -s 2>$null)
                } catch {}
                if ($uname -eq "Darwin") {
                    "macOS"
                } else {
                    "Linux"
                }
            }
            default { $platform }
        }
        
        # Get friendly OS version
        $friendlyOsVersion = switch ($platform) {
            "Win32NT" {
                try {
                    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
                    if ($osInfo) {
                        $osInfo.Caption -replace "Microsoft ", ""
                    } else {
                        [System.Environment]::OSVersion.VersionString
                    }
                }
                catch {
                    [System.Environment]::OSVersion.VersionString
                }
            }
            "Unix" {
                if ($friendlyPlatform -eq "macOS") {
                    try {
                        $macVersion = (& sw_vers -productVersion 2>$null)
                        if ($macVersion) {
                            "macOS $macVersion"
                        } else {
                            [System.Environment]::OSVersion.VersionString
                        }
                    }
                    catch {
                        [System.Environment]::OSVersion.VersionString
                    }
                } else {
                    # Linux
                    try {
                        $linuxVersion = ""
                        if (Test-Path "/etc/os-release") {
                            $osRelease = Get-Content "/etc/os-release" | Where-Object { $_ -like "PRETTY_NAME=*" }
                            if ($osRelease) {
                                $linuxVersion = ($osRelease -split '=')[1] -replace '"', ''
                            }
                        }
                        if ($linuxVersion) {
                            $linuxVersion
                        } else {
                            [System.Environment]::OSVersion.VersionString
                        }
                    }
                    catch {
                        [System.Environment]::OSVersion.VersionString
                    }
                }
            }
            default {
                [System.Environment]::OSVersion.VersionString
            }
        }
        
        # Handle versioning and preserve existing config
        $currentVersion = "1.0.0"  # Default version for new files
        $baseConfig = @{
            devsetup = @{
                dependencies = @{
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
                configuration = @{
                    description = "Auto-generated development environment configuration"
                    version = $currentVersion
                    createdDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    createdBy = $env:USERNAME
                    os = @{
                        name = $friendlyPlatform
                        version = $friendlyOsVersion
                        architecture = $osArchitecture
                    }
                    powershell = @{
                        version = $PSVersionTable.PSVersion.ToString()
                        edition = $PSVersionTable.PSEdition
                    }
                }
            }
        }
        
        if (Test-Path $OutFile) {
            try {
                Write-Host "- Using existing configuration..." -ForegroundColor Gray
                $existingConfig = Read-ConfigurationFile -Config $OutFile
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
                            Write-Host "- Version: $existingVersionString -> $currentVersion" -ForegroundColor Gray
                        }
                        catch {
                            Write-Warning "- Version: $currentVersion"
                        }
                    } else {
                        Write-Host "- Version: $currentVersion" -ForegroundColor Gray
                    }
                    
                    # Preserve other configuration fields but update system info
                    if ($existingConfig.devsetup.configuration) {
                        $baseConfig.devsetup.configuration.description = $existingConfig.devsetup.configuration.description
                        $baseConfig.devsetup.configuration.createdBy = $existingConfig.devsetup.configuration.createdBy
                        if ($existingConfig.devsetup.configuration.createdDate) {
                            # Keep original creation date, but we could add a lastModified field
                            $baseConfig.devsetup.configuration.createdDate = $existingConfig.devsetup.configuration.createdDate
                            $baseConfig.devsetup.configuration.lastModified = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        }
                    }
                }
            }
            catch {
                Write-Warning "Failed to read existing configuration for merging: $_"
                Write-Host "- Using new configuration with default version: $currentVersion" -ForegroundColor Gray
            }
        } else {
            Write-Host "- Using new configuration file, starting with version: $currentVersion" -ForegroundColor Green
        }
        
        try {
            $yamlOutput = $baseConfig | ConvertTo-Yaml
            $yamlOutput | Out-File -FilePath $OutFile -Encoding UTF8
            Write-Debug "Base configuration file created successfully!"
        }
        catch {
            Write-Error "Failed to create base configuration file: $_"
            return $false
        }

        # Convert from installed Chocolatey packages
        Write-Host "`nScanning installed Chocolatey packages..." -ForegroundColor Cyan
        if (-not (Export-InstalledChocolateyPackages -Config $OutFile)) {
            Write-Warning "Failed to convert Chocolatey packages, but continuing..."
        }

        # Convert from installed Scoop packages
        Write-Host "`nScanning installed Scoop packages..." -ForegroundColor Cyan
        if (-not (Export-InstalledScoopPackages -Config $OutFile)) {
            Write-Warning "Failed to convert Scoop packages, but continuing..."
        }

        # Convert from installed PowerShell modules
        Write-Host "`nScanning installed PowerShell modules..." -ForegroundColor Cyan
        if (-not (Export-InstalledPowershellModules -Config $OutFile)) {
            Write-Warning "Failed to convert PowerShell modules, but continuing..."
        }

        ConvertFrom-3rdPartyInstall -Config $OutFile

        Write-Host "`nConfiguration file generation completed!" -ForegroundColor Green
        Write-Host "- Configuration saved to: $OutFile" -ForegroundColor Gray
        Write-Host ""

        Optimize-DevSetupEnvs
        return $true
    }
    catch {
        Write-Error "Error creating new configuration: $_"
        return $false
    }
}