<#
.SYNOPSIS
    Installs Scoop buckets and packages from YAML configuration data.

.DESCRIPTION
    This function processes YAML configuration data to install Scoop buckets and packages in sequence.
    It validates Scoop installation, updates the cache before proceeding, and processes buckets before
    packages to ensure bucket availability. The function supports object formats for buckets and packages,
    allowing for detailed configuration including versions, custom sources, and global installation scope. 
    Progress is tracked and reported for both buckets and packages using color-coded status messages.

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
    Invoke-ScoopComponentInstall -YamlData $yamlData
    
    Installs Scoop buckets and packages from a YAML configuration file.

.EXAMPLE
    $yamlData = @{
        devsetup = @{
            dependencies = @{
                scoop = @{
                    buckets = @(
                        @{
                            name = "extras"
                            source = "https://github.com/ScoopInstaller/Extras"
                        },
                        @{
                            name = "custom-bucket"
                            source = "https://github.com/user/scoop-bucket"
                        }
                    )
                    packages = @(
                        @{
                            name = "git"
                            bucket = "main"
                        },
                        @{
                            name = "nodejs"
                            version = "18.17.0"
                            bucket = "main"
                        },
                        @{
                            name = "7zip"
                            bucket = "main"
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
    Invoke-ScoopComponentInstall -YamlData $yamlData
    
    Demonstrates the PSCustomObject structure and installs the configured components.

.EXAMPLE
    if (Invoke-ScoopComponentInstall -YamlData $config) {
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
    - All bucket entries must be hashtables/objects with 'name' and 'source' fields:
      * @{ name = "bucketname"; source = "https://github.com/user/scoop-bucket" }
    - All package entries must be hashtables/objects with 'name' and 'bucket' fields:
      * @{ name = "packagename"; bucket = "main"; version = "1.0.0"; global = $true }
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
Function Invoke-ScoopComponentInstall {
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
    } catch {
        Write-StatusMessage "Could not verify Scoop installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        if (-not (Write-ScoopCache)) {
            Write-Error "Failed to write Scoop cache file: $CacheFilePath"
            return $false
        }
    } catch {
        Write-StatusMessage "Could not update Scoop cache: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    $bucketCount = 0
    Write-StatusMessage "- Installing Scoop buckets from configuration:" -ForegroundColor Cyan
    # Handle buckets first if they exist in configuration
    $buckets = $YamlData.devsetup.dependencies.scoop.buckets
    if ($buckets.Count -gt 0) {
        foreach ($bucket in $buckets) {
            if (-not $bucket -or [string]::IsNullOrEmpty($bucket.name)) { 
                Write-StatusMessage "- Skipping bucket entry, No name specified" -Verbosity "Warning" -Indent 2 -Width 112
                continue 
            }
            
            # Handle both string format and object format
            $bucketName = $bucket.name
            $bucketSource = if ($bucket.source) { $bucket.source } else { $null }
            
            $installParams = @{
                Name = $bucketName
                WhatIf = $DryRun
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

    Write-StatusMessage "- Scoop buckets installation completed! Processed $bucketCount buckets.`n" -ForegroundColor Green

    $packageCount = 0
    Write-StatusMessage "- Installing Scoop packages from configuration:" -ForegroundColor Cyan
    $scoopPackages = $YamlData.devsetup.dependencies.scoop.packages
    
    if ($scoopPackages.Count -gt 0) {
        # Install packages
        foreach ($package in $scoopPackages) {
            if (-not $package -or [string]::IsNullOrEmpty($package.name)) { 
                Write-StatusMessage "- Skipping package entry, No name specified" -Verbosity "Warning" -Indent 2 -Width 112
                continue 
            }
            
            # Use Install-ScoopPackage function to handle the installation
            $displayName = $package.name
            $installParams = @{
                PackageName = $package.name
                WhatIf = $DryRun
            }
            
            $versionDisplay = ""
            if ($package.version) {
                $versionDisplay = "version: $($package.version)"
                $installParams.Version = $package.version
            }
            
            $bucketDisplay = ""
            if ($package.bucket) {
                $bucketDisplay = "bucket: '$($package.bucket)'"
                $installParams.Bucket = $package.bucket
            }
            
            $globalDisplay = ""
            if ($package.global -eq $true) {
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

            try {
                $result = Install-ScoopPackage @installParams

                if ($LASTEXITCODE -ne 0 -or -not $result) {
                    Write-StatusMessage "[FAILED]" -ForegroundColor Red
                } else {
                    Write-StatusMessage "[OK]" -ForegroundColor Green
                    $packageCount++
                }
            } catch {
                Write-StatusMessage "Failed to install Scoop package '$($package.name)': $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                continue
            }
        }
    }

    Write-StatusMessage "- Scoop packages installation completed! Processed $packageCount packages.`n" -ForegroundColor Green

    return $true
}