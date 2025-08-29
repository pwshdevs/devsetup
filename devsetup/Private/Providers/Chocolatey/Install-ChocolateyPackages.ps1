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
    Install-ChocolateyPackages -YamlData $yamlData
    
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
    Install-ChocolateyPackages -YamlData $yamlData
    
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

Function Install-ChocolateyPackages {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$YamlData
    )
    
    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "Chocolatey package installation requires administrator privileges. Please run as administrator."
        }
        
        # Check if chocolatey dependencies exist
        if (-not $YamlData -or -not $YamlData.devsetup -or -not $YamlData.devsetup.dependencies -or -not $YamlData.devsetup.dependencies.chocolatey -or -not $YamlData.devsetup.dependencies.chocolatey.packages) {
            Write-Warning "Chocolatey packages not found in YAML configuration. Skipping installation."
            return
        }

        if (-not (Write-ChocolateyCache)) {
            Write-Warning "Failed to write Chocolatey cache."
            return $false
        }

        $chocolateyPackages = $YamlData.devsetup.dependencies.chocolatey.packages
        Write-StatusMessage "- Installing Chocolatey packages from configuration:" -ForegroundColor Cyan
        
        $packageCount = 0
        
        foreach ($package in $chocolateyPackages) {
            if (-not $package) { continue }
            
            $packageCount++
            
            # Normalize package to object format
            if ($package -is [string]) {
                $packageObj = @{ name = $package }
            } else {
                $packageObj = $package
            }
            
            # Validate package name
            if ([string]::IsNullOrEmpty($packageObj.name)) {
                Write-Warning "Package entry #$packageCount has no name specified, skipping"
                continue
            }
            
            # Build install parameters
            $installParams = @{ 
                PackageName = $packageObj.name 
            }
            if ($packageObj.version) {
                $installParams.Version = $packageObj.version
                Write-StatusMessage "- Installing Chocolatey package: $($packageObj.name) (version: $($packageObj.version))" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewline
            } else {
                Write-StatusMessage "- Installing Chocolatey package: $($packageObj.name) (version: latest)" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewline
            }

            if($packageObj.params) {
                $installParams.Param = $packageObj.params
            }

            #$installParams.Debug = $true

            if((Install-ChocolateyPackage @installParams)) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            }
        }

        Write-StatusMessage "- Chocolatey packages installation completed! Processed $packageCount packages." -ForegroundColor Green
        write-host ""
        return $true
    }
    catch {
        Write-Error "Error installing Chocolatey packages: $_"
        return $false
    }    
}