<#
.SYNOPSIS
    Uninstalls multiple Chocolatey packages from the system based on YAML configuration.

.DESCRIPTION
    This function removes multiple Chocolatey packages specified in a DevSetup YAML configuration.
    It validates administrator privileges, parses the configuration for Chocolatey package definitions,
    and systematically uninstalls each package. The function supports both simple string format and
    complex object format for package specifications, handles version constraints, and provides
    comprehensive progress reporting during the uninstallation process.

.PARAMETER YamlData
    The parsed YAML configuration data containing Chocolatey package definitions.
    This parameter is mandatory and must be a PSCustomObject with the structure:
    devsetup.dependencies.chocolatey.packages containing an array of package specifications.

.OUTPUTS
    [System.Boolean]
    Returns $true if all packages are successfully processed (even if some individual uninstalls fail).
    Returns $false if the operation encounters critical errors or cannot proceed.

.EXAMPLE
    $config = Read-ConfigurationFile -Path "environment.yaml"
    Uninstall-ChocolateyPackages -YamlData $config
    
    Uninstalls all Chocolatey packages defined in the environment.yaml configuration.

.EXAMPLE
    $yamlData = @{
        devsetup = @{
            dependencies = @{
                chocolatey = @{
                    packages = @("git", "nodejs", "vscode")
                }
            }
        }
    }
    Uninstall-ChocolateyPackages -YamlData $yamlData
    
    Demonstrates uninstalling packages using a programmatically created configuration.

.EXAMPLE
    if (Uninstall-ChocolateyPackages -YamlData $config) {
        Write-Host "All Chocolatey packages processed successfully"
    } else {
        Write-Host "Chocolatey uninstallation encountered errors"
    }
    
    Shows checking the return value to verify uninstallation completion.

.NOTES
    - Requires administrator privileges to uninstall Chocolatey packages
    - Uses Test-RunningAsAdmin to validate privileges before proceeding
    - Throws an exception if not running as administrator
    - Updates Chocolatey cache using Write-ChocolateyCache before uninstallation
    - Skips uninstallation gracefully if no Chocolatey packages are found in configuration
    - Supports two package specification formats:
      * Simple string: "packagename"
      * Complex object: @{ name = "packagename"; version = "1.0.0" }
    - Validates package names and skips entries with missing names
    - Uses Uninstall-ChocolateyPackage for individual package removal
    - Provides detailed progress reporting with package counts and status indicators
    - Uses color-coded console output: Cyan for progress, Gray for package status, Green/Red for results
    - Continues processing remaining packages even if individual uninstalls fail
    - Returns $true for overall success even with individual package failures
    - Includes comprehensive try-catch error handling with descriptive error messages

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Package Management, Batch Uninstallation, Configuration Processing, System Cleanup
#>

Function Uninstall-ChocolateyPackages {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$YamlData
    )
    
    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "Chocolatey package uninstallation requires administrator privileges. Please run as administrator."
        }
        
        # Check if chocolatey dependencies exist
        if (-not $YamlData -or -not $YamlData.devsetup -or -not $YamlData.devsetup.dependencies -or -not $YamlData.devsetup.dependencies.chocolatey -or -not $YamlData.devsetup.dependencies.chocolatey.packages) {
            Write-Warning "Chocolatey packages not found in YAML configuration. Skipping uninstallation."
            return
        }

        if (-not (Write-ChocolateyCache)) {
            Write-Warning "Failed to write Chocolatey cache."
            return $false
        }

        $chocolateyPackages = $YamlData.devsetup.dependencies.chocolatey.packages
        Write-StatusMessage "- Uninstalling Chocolatey packages from configuration:" -ForegroundColor Cyan
        
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
                Write-StatusMessage "- Uninstalling Chocolatey package: $($packageObj.name) (version: $($packageObj.version))" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewline
            } else {
                Write-StatusMessage "- Uninstalling Chocolatey package: $($packageObj.name) (version: latest)" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewline
            }

            if((Uninstall-ChocolateyPackage @installParams)) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            }
        }

        Write-StatusMessage "- Chocolatey packages uninstallation completed! Processed $packageCount packages." -ForegroundColor Green
        write-host ""
        return $true
    }
    catch {
        Write-Error "Error uninstalling Chocolatey packages: $_"
        return $false
    }    
}