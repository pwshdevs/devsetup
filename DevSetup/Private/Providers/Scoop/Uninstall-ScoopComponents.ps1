<#
.SYNOPSIS
    Uninstalls multiple Scoop components (buckets and packages) from the system based on YAML configuration.

.DESCRIPTION
    This function removes multiple Scoop components specified in a DevSetup YAML configuration.
    It validates Scoop installation, parses the configuration for bucket and package definitions,
    and systematically uninstalls components in the correct order (buckets first, then packages).
    The function supports both simple string format and complex object format for component
    specifications, handles global installations, and provides comprehensive progress reporting
    during the uninstallation process.

.PARAMETER YamlData
    The parsed YAML configuration data containing Scoop component definitions.
    This parameter is mandatory and must be a PSCustomObject with the structure:
    devsetup.dependencies.scoop containing buckets and/or packages arrays.

.OUTPUTS
    [System.Boolean]
    Returns $true if all components are successfully processed (even if some individual uninstalls fail).
    Returns $false if the operation encounters critical errors, Scoop is not installed, or cannot proceed.

.EXAMPLE
    $config = Read-ConfigurationFile -Path "environment.yaml"
    Uninstall-ScoopComponents -YamlData $config
    
    Uninstalls all Scoop buckets and packages defined in the environment.yaml configuration.

.EXAMPLE
    $yamlData = @{
        devsetup = @{
            dependencies = @{
                scoop = @{
                    buckets = @("extras", "versions")
                    packages = @("git", "nodejs", "python")
                }
            }
        }
    }
    Uninstall-ScoopComponents -YamlData $yamlData
    
    Demonstrates uninstalling components using a programmatically created configuration.

.EXAMPLE
    if (Uninstall-ScoopComponents -YamlData $config) {
        Write-Host "All Scoop components processed successfully"
    } else {
        Write-Host "Scoop component uninstallation encountered errors"
    }
    
    Shows checking the return value to verify uninstallation completion.

.NOTES
    - Requires Scoop to be installed on the system
    - Uses Test-ScoopInstalled to validate Scoop availability before proceeding
    - Updates Scoop cache using Write-ScoopCache before uninstallation begins
    - Processes components in specific order: buckets first, then packages
    - Skips uninstallation gracefully if Scoop configuration sections are not found
    - Supports two component specification formats for both buckets and packages:
      * Simple string: "componentname"
      * Complex object: @{ name = "componentname"; version = "1.0.0"; bucket = "extras"; global = $true }
    - Bucket objects support: name and source properties
    - Package objects support: name, version, bucket, and global properties
    - Validates component names and skips entries with missing names
    - Uses Uninstall-ScoopBucket and Uninstall-ScoopPackage for individual component removal
    - Provides detailed progress reporting with component counts and property information
    - Uses color-coded console output: Cyan for progress, Gray for component status, Green/Red for results
    - Continues processing remaining components even if individual uninstalls fail
    - Returns $true for overall success even with individual component failures
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Displays formatted component information including version, bucket, and global flags

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Package Management, Batch Uninstallation, Configuration Processing, Component Management
#>

Function Uninstall-ScoopComponents {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$YamlData
    )
    
    try {
        if(-Not (Test-ScoopInstalled)) {
            Write-StatusMessage "Scoop is not installed. Cannot check for components." -Verbosity "Warning"
            return $false
        }
        
        # Check if scoop packages exist in configuration
        if (-not $YamlData -or -not $YamlData.devsetup -or -not $YamlData.devsetup.dependencies -or -not $YamlData.devsetup.dependencies.scoop) {
            Write-StatusMessage "Scoop configuration not found in YAML. Skipping uninstallation." -Verbosity "Warning"
            return $false
        }

        if (-not (Write-ScoopCache)) {
            Write-Error "Failed to write Scoop cache file: $CacheFilePath"
            return $false
        }

        $bucketCount = 0
        # Handle buckets first if they exist in configuration
        if ($YamlData.devsetup.dependencies.scoop.buckets) {
            Write-StatusMessage "- Uninstalling Scoop buckets from configuration:" -ForegroundColor Cyan
            foreach ($bucket in $YamlData.devsetup.dependencies.scoop.buckets) {
                if (-not $bucket) { continue }
                
                # Handle both string format and object format
                $bucketName = if ($bucket -is [string]) { $bucket } else { $bucket.name }
                $bucketSource = if ($bucket -is [hashtable] -and $bucket.source) { $bucket.source } else { $null }
                
                $installParams = @{
                    Name = $bucketName
                }

                # Use Install-ScoopBucket function to handle bucket installation
                if ($bucketName -and $bucketSource) {
                    Write-StatusMessage "- Removing Scoop bucket: $bucketName (source: $bucketSource)" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewLine
                } else {
                    Write-StatusMessage "- Removing Scoop bucket: $bucketName" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewLine
                }
                
                $installationStatus = Uninstall-ScoopBucket @installParams

                if (-not $installationStatus) {
                    Write-StatusMessage "[FAILED]" -ForegroundColor Red
                } else {
                    $bucketCount++
                    Write-StatusMessage "[OK]" -ForegroundColor Green                    
                }
            }
        }

        Write-StatusMessage "- Scoop buckets uninstallation completed! Processed $bucketCount buckets." -ForegroundColor Green

        Write-Host ""

        # Check if scoop packages exist in configuration
        if (-not $YamlData.devsetup.dependencies.scoop.packages) {
            Write-StatusMessage "Scoop packages not found in YAML configuration. Skipping package uninstallation." -Verbosity "Warning"
            return $true
        }

        $scoopPackages = $YamlData.devsetup.dependencies.scoop.packages
        Write-StatusMessage "- Uninstalling Scoop packages from configuration:" -ForegroundColor Cyan
        
        $packageCount = 0
        
        # Install packages
        foreach ($package in $scoopPackages) {
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
                Write-StatusMessage "- Skipping package entry, No name specified" -Verbosity "Warning" -Indent 2 -Width 100
                continue
            }
            
            # Use Install-ScoopPackage function to handle the installation
            try {
                $displayName = $packageObj.name
                $installParams = @{
                    PackageName = $packageObj.name
                }
                
                $versionDisplay = ""
                if ($packageObj.version) {
                    $versionDisplay = "version: $($packageObj.version)"
                }
                
                $bucketDisplay = ""
                if ($packageObj.bucket) {
                    $bucketDisplay = "bucket: '$($packageObj.bucket)'"
                }
                
                $globalDisplay = ""
                if ($packageObj.global -eq $true) {
                    $globalDisplay = "global: true"
                    $installParams.Global = $true
                }

                if($versionDisplay -or $bucketDisplay -or $globalDisplay) {
                    $parts = @($versionDisplay, $bucketDisplay, $globalDisplay) | Where-Object { $_ }
                    $displayName += " (" + ($parts -join ", ") + ")"
                }
                Write-StatusMessage "- Uninstalling Scoop package: $displayName" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewLine

                $result = Uninstall-ScoopPackage @installParams
                
                if (-not $result) {
                    Write-StatusMessage "[FAILED]" -ForegroundColor Red
                } else {
                    Write-StatusMessage "[OK]" -ForegroundColor Green
                }
            } catch {
                Write-StatusMessage "Failed to uninstall Scoop package '$($packageObj.name)': $_" -Verbosity "Error"
                continue
            }
        }

        Write-StatusMessage "- Scoop packages uninstallation completed! Processed $packageCount packages." -ForegroundColor Green

        Write-Host ""

        return $true
    }
    catch {
        Write-StatusMessage "Error uninstalling Scoop packages: $_" -Verbosity "Error"
        return $false
    }
}