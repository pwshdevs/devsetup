<#
.SYNOPSIS
    Installs Chocolatey packages from YAML configuration data.

.DESCRIPTION
    This function processes YAML configuration data to install Chocolatey packages using Install-ChocolateyPackage.
    It supports both simple string formats and complex object formats for packages, allowing for detailed 
    configuration including versions and custom installation parameters. The function validates administrator 
    privileges before proceeding and provides comprehensive error handling and progress reporting throughout 
    the installation process.

.PARAMETER YamlData
    The YAML configuration data containing Chocolatey package definitions.
    This parameter is mandatory and must be a PSCustomObject with the structure:
    devsetup.dependencies.chocolatey.packages

.OUTPUTS
    [System.Boolean]
    Returns $true if installation completes successfully (even if individual packages fail).
    Returns $false if configuration is invalid or critical errors occur.

.EXAMPLE
    $yamlData = Get-Content "config.yaml" | ConvertFrom-Yaml
    Invoke-ChocolateyPackageInstall -YamlData $yamlData
    
    Installs Chocolatey packages from a YAML configuration file.

.EXAMPLE
    $yamlData = @{
        devsetup = @{
            dependencies = @{
                chocolatey = @{
                    packages = @(
                        "git",
                        @{
                            name = "nodejs"
                            version = "18.17.0"
                        },
                        @{
                            name = "googlechrome"
                            params = "/nogoogle"
                        },
                        @{
                            name = "vscode"
                            version = "1.75.0"
                            params = "/silent"
                        }
                    )
                }
            }
        }
    }
    Invoke-ChocolateyPackageInstall -YamlData $yamlData
    
    Demonstrates the PSCustomObject structure and installs the configured packages.

.NOTES
    - Requires administrator privileges to install Chocolatey packages
    - Uses Test-RunningAsAdmin to validate privileges before proceeding
    - Throws an exception if not running as administrator
    - Returns early with warning if Chocolatey packages configuration is missing
    - Supports both string and object formats for package definitions:
      * String format: Simple package name for latest version
      * Object format: Supports name (required), version (optional), params (optional)
    - Skips empty or invalid entries in the configuration without stopping execution
    - Uses Install-ChocolateyPackage function for actual installation
    - Provides detailed progress reporting with color-coded status messages
    - Individual installation failures do not stop the overall process
    - Tracks and reports installation counts for all processed packages
    - Uses parameter splatting for reliable package installation
    - Displays installation status ([OK]/[FAILED]) for each package

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Bulk Installation, Configuration Processing, Package Management
#>

Function Invoke-ChocolateyPackageInstall {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$YamlData,
        [switch]$DryRun
    )
    
    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            Write-StatusMessage "Chocolatey package installation requires administrator privileges. Please run as administrator." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking administrator privileges: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

        
    # Check if chocolatey dependencies exist
    if (-not $YamlData -or -not $YamlData.devsetup -or -not $YamlData.devsetup.dependencies -or -not $YamlData.devsetup.dependencies.chocolatey -or -not $YamlData.devsetup.dependencies.chocolatey.packages) {
        Write-StatusMessage "Chocolatey packages not found in YAML configuration. Skipping installation." -Verbosity Warning
        return $false
    }

    try {
        if (-not (Write-ChocolateyCache)) {
            Write-StatusMessage "Failed to write Chocolatey cache." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error writing Chocolatey cache: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    $chocolateyPackages = $YamlData.devsetup.dependencies.chocolatey.packages
    Write-StatusMessage "- Installing Chocolatey packages from configuration:" -ForegroundColor Cyan
    
    $packageCount = 0
    
    foreach ($package in $chocolateyPackages) {
        if (-not $package) { continue }
        
        $packageCount++
        
        # Validate package name
        if ([string]::IsNullOrEmpty($package.name)) {
            Write-StatusMessage "Package entry #$packageCount has no name specified, skipping" -Verbosity Warning
            continue
        }
        
        # Build install parameters
        $installParams = @{ 
            PackageName = $package.name 
            WhatIf = $DryRun
        }
        if ($package.version) {
            $installParams.Version = $package.version
            Write-StatusMessage "- Installing Chocolatey package: $($package.name) (version: $($package.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
        } else {
            Write-StatusMessage "- Installing Chocolatey package: $($package.name) (version: latest)" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
        }

        if($package.params) {
            $installParams.Param = $package.params
        }

        #$installParams.Debug = $true
        try {
            if((Install-ChocolateyPackage @installParams)) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            }
        } catch {
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            Write-StatusMessage "Error installing package $($package.name): $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        }
    }

    Write-StatusMessage "- Chocolatey packages installation completed! Processed $packageCount packages.`n" -ForegroundColor Green
    return $true  
}