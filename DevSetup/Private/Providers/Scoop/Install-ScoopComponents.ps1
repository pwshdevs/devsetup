<#
.SYNOPSIS
    Installs Scoop buckets and packages from YAML configuration data.

.DESCRIPTION
    This function processes YAML configuration data to install Scoop buckets and packages in sequence.
    It validates Scoop installation, updates the cache before proceeding, and processes buckets before
    packages to ensure bucket availability. The function supports both simple string formats and complex
    object formats for buckets and packages, allowing for detailed configuration including versions,
    custom sources, and global installation scope. Progress is tracked and reported for both buckets
    and packages using color-coded status messages.

.PARAMETER YamlData
    The YAML configuration data containing Scoop bucket and package definitions.
    This parameter is mandatory and must be a PSCustomObject with the structure:
    devsetup.dependencies.scoop.buckets and/or devsetup.dependencies.scoop.packages

.OUTPUTS
    [System.Boolean]
    Returns $false if Scoop is not installed, cannot be found, configuration is invalid, or cache update fails.
    Returns $true if installation completes successfully (even if individual items fail).

.EXAMPLE
    $yamlData = Get-Content "config.yaml" | ConvertFrom-Yaml
    Install-ScoopComponents -YamlData $yamlData
    
    Installs Scoop buckets and packages from a YAML configuration file.

.EXAMPLE
    $yamlData = @{
        devsetup = @{
            dependencies = @{
                scoop = @{
                    buckets = @(
                        "extras",
                        @{
                            name = "custom-bucket"
                            source = "https://github.com/user/scoop-bucket"
                        }
                    )
                    packages = @(
                        "git",
                        @{
                            name = "nodejs"
                            version = "18.17.0"
                        },
                        @{
                            name = "7zip"
                            global = $true
                        },
                        @{
                            name = "firefox"
                            bucket = "extras"
                        }
                    )
                }
            }
        }
    }
    Install-ScoopComponents -YamlData $yamlData
    
    Demonstrates the PSCustomObject structure and installs the configured components.

.EXAMPLE
    if (Install-ScoopComponents -YamlData $config) {
        Write-Host "Scoop components installation completed"
    } else {
        Write-Host "Scoop components installation failed"
    }
    
    Shows checking the return value to verify installation completion.

.NOTES
    - Requires Scoop to be installed on the system using Test-ScoopInstalled
    - Returns $false immediately if Scoop is not installed or cannot be found
    - Returns $false if YAML configuration structure is invalid or missing scoop section
    - Updates Scoop cache using Write-ScoopCache before installation begins
    - Returns $false if cache update fails to ensure accurate installation state
    - Processes buckets before packages to ensure bucket availability for package installations
    - Gracefully handles missing buckets or packages sections in configuration
    - Supports two bucket specification formats:
      * Simple string: "bucketname"
      * Complex object: @{ name = "bucketname"; source = "https://github.com/user/scoop-bucket" }
    - Supports two package specification formats:
      * Simple string: "packagename"
      * Complex object: @{ name = "packagename"; version = "1.0.0"; bucket = "extras"; global = $true }
    - Validates component names and skips entries with missing names
    - Uses Install-ScoopBucket and Install-ScoopPackage functions for actual installation
    - Provides detailed progress reporting with component counts and property information
    - Uses color-coded console output: Cyan for headers, Gray for items, Green/Red for status
    - Displays formatted component information including version, bucket, and global flags
    - Continues processing remaining components even if individual installations fail
    - Returns $true for overall success even with individual component failures
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Tracks and reports separate counts for buckets and packages processed

.LINK

.COMPONENT
    DevSetup.Scoop

.FUNCTIONALITY
    Bulk Installation, Configuration Processing, Package Management
#>
Function Install-ScoopComponents {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$YamlData,
        [switch]$DryRun
    )
    
    try {
        if(-Not (Test-ScoopInstalled)) {
            Write-StatusMessage "Scoop is not installed. Cannot check for components." -Verbosity "Warning"
            return $false
        }
        
        # Check if scoop packages exist in configuration
        if (-not $YamlData -or -not $YamlData.devsetup -or -not $YamlData.devsetup.dependencies -or -not $YamlData.devsetup.dependencies.scoop) {
            Write-StatusMessage "Scoop configuration not found in YAML. Skipping installation." -Verbosity "Warning"
            return $false
        }

        if (-not (Write-ScoopCache)) {
            Write-Error "Failed to write Scoop cache file: $CacheFilePath"
            return $false
        }

        $bucketCount = 0
        Write-StatusMessage "- Installing Scoop buckets from configuration:" -ForegroundColor Cyan
        # Handle buckets first if they exist in configuration
        if ($YamlData.devsetup.dependencies.scoop.buckets) {
            foreach ($bucket in $YamlData.devsetup.dependencies.scoop.buckets) {
                if (-not $bucket) { continue }
                
                # Handle both string format and object format
                $bucketName = if ($bucket -is [string]) { $bucket } else { $bucket.name }
                $bucketSource = if ($bucket -is [hashtable] -and $bucket.source) { $bucket.source } else { $null }
                
                $installParams = @{
                    Name = $bucketName
                }

                if ($bucketSource) {
                    $installParams.Source = $bucketSource
                }

                # Use Install-ScoopBucket function to handle bucket installation
                if ($bucketName -and $bucketSource) {
                    Write-StatusMessage "- Adding Scoop bucket: $bucketName (source: $bucketSource)" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
                } else {
                    Write-StatusMessage "- Adding Scoop bucket: $bucketName" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
                }
                
                $installationStatus = Install-ScoopBucket @installParams

                if (-not $installationStatus) {
                    Write-StatusMessage "[FAILED]" -ForegroundColor Red
                } else {
                    $bucketCount++
                    Write-StatusMessage "[OK]" -ForegroundColor Green                    
                }
            }
        }

        Write-StatusMessage "- Scoop buckets installation completed! Processed $bucketCount buckets." -ForegroundColor Green

        Write-Host ""

        # Check if scoop packages exist in configuration
        if (-not $YamlData.devsetup.dependencies.scoop.packages) {
            Write-StatusMessage "Scoop packages not found in YAML configuration. Skipping package installation." -Verbosity "Warning"
            return $true
        }

        $scoopPackages = $YamlData.devsetup.dependencies.scoop.packages
        Write-StatusMessage "- Installing Scoop packages from configuration:" -ForegroundColor Cyan
        
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
                Write-StatusMessage "- Skipping package entry, No name specified" -Verbosity "Warning" -Indent 2 -Width 112
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
                    $installParams.Version = $packageObj.version
                }
                
                $bucketDisplay = ""
                if ($packageObj.bucket) {
                    $bucketDisplay = "bucket: '$($packageObj.bucket)'"
                    $installParams.Bucket = $packageObj.bucket
                }
                
                $globalDisplay = ""
                if ($packageObj.global -eq $true) {
                    $globalDisplay = "global: true"
                    $installParams.Global = $true
                } else {
                    $installParams.Global = $false
                }

                if($versionDisplay -or $bucketDisplay -or $globalDisplay) {
                    $parts = @($versionDisplay, $bucketDisplay, $globalDisplay) | Where-Object { $_ }
                    $displayName += " (" + ($parts -join ", ") + ")"
                }
                Write-StatusMessage "- Installing Scoop package: $displayName" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine

                $result = Install-ScoopPackage @installParams 2>$null 3>$null 4>$null 5>$null 6>$null
                
                if (-not $result) {
                    Write-StatusMessage "[FAILED]" -ForegroundColor Red
                } else {
                    Write-StatusMessage "[OK]" -ForegroundColor Green
                }
            } catch {
                Write-StatusMessage "Failed to install Scoop package '$($packageObj.name)': $_" -Verbosity "Error"
                continue
            }
        }

        Write-StatusMessage "- Scoop packages installation completed! Processed $packageCount packages." -ForegroundColor Green

        Write-Host ""

        return $true
    }
    catch {
        Write-StatusMessage "Error installing Scoop packages: $_" -Verbosity "Error"
        return $false
    }
}