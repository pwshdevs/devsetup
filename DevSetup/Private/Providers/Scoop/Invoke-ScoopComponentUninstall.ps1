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
    Invoke-ScoopComponentUninstall -YamlData $config
    
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
    Invoke-ScoopComponentUninstall -YamlData $yamlData
    
    Demonstrates uninstalling components using a programmatically created configuration.

.EXAMPLE
    if (Invoke-ScoopComponentUninstall -YamlData $config) {
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

Function Invoke-ScoopComponentUninstall {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$YamlData,
        [switch]$DryRun
    )
    
    try {
        if(-Not (Test-ScoopInstalled)) {
            Write-StatusMessage "Scoop is not installed. Cannot check for components." -Verbosity Warning
            return $false
        }
    } catch {
        Write-StatusMessage "Scoop is not installed. $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        if (-not (Write-ScoopCache)) {
            Write-StatusMessage "Failed to write Scoop cache file: $CacheFilePath" -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error writing Scoop cache: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    $bucketCount = 0
    Write-StatusMessage "- Uninstalling Scoop buckets from configuration:" -ForegroundColor Cyan
    $buckets = $YamlData.devsetup.dependencies.scoop.buckets
    # Handle buckets first if they exist in configuration
    if ($buckets.Count -gt 0) {
        foreach ($bucket in $buckets) {
            if (-not $bucket -or [string]::IsNullOrEmpty($bucket.name)) { 
                Write-StatusMessage "- Skipping bucket entry, No name specified" -Verbosity "Warning" -Indent 2 -Width 112
                continue 
            }
            
            $uninstallParams = @{
                Name = $bucket.name
                WhatIf = $DryRun
            }

            # Use Install-ScoopBucket function to handle bucket installation
            if ($bucket.name -and $bucket.source) {
                Write-StatusMessage "- Removing Scoop bucket: $($bucket.name) (source: $($bucket.source))" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewLine
            } else {
                Write-StatusMessage "- Removing Scoop bucket: $($bucket.name)" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewLine
            }
            
            try {
                $uninstallationStatus = Uninstall-ScoopBucket @uninstallParams
            } catch {
                Write-StatusMessage "Failed to uninstall Scoop bucket '$($bucket.name)': $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                continue
            }

            if (-not $uninstallationStatus) {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            } else {
                $bucketCount++
                Write-StatusMessage "[OK]" -ForegroundColor Green                    
            }
        }
    }

    Write-StatusMessage "- Scoop buckets uninstallation completed! Processed $bucketCount buckets.`n" -ForegroundColor Green

    $packageCount = 0
    Write-StatusMessage "- Uninstalling Scoop packages from configuration:" -ForegroundColor Cyan
    $packages = $YamlData.devsetup.dependencies.scoop.packages

    if ($packages.Count -gt 0) {
        # Install packages
        foreach ($package in $packages) {
            if (-not $package -or [string]::IsNullOrWhiteSpace($package.name)) { continue }
            
            $displayName = $package.name
            $uninstallParams = @{
                PackageName = $package.name
                WhatIf = $DryRun
            }
            
            $versionDisplay = ""
            if ($package.version) {
                $versionDisplay = "version: $($package.version)"
            }
            
            $bucketDisplay = ""
            if ($package.bucket) {
                $bucketDisplay = "bucket: '$($package.bucket)'"
            }
            
            $globalDisplay = ""
            if ($package.global -eq $true) {
                $globalDisplay = "global: true"
                $uninstallParams.Global = $true
            }

            if($versionDisplay -or $bucketDisplay -or $globalDisplay) {
                $parts = @($versionDisplay, $bucketDisplay, $globalDisplay) | Where-Object { $_ }
                $displayName += " (" + ($parts -join ", ") + ")"
            }
            
            Write-StatusMessage "- Uninstalling Scoop package: $displayName" -ForegroundColor Gray -Indent 2 -Width 100 -NoNewLine

            try {
                $result = Uninstall-ScoopPackage @uninstallParams
            } catch {
                Write-StatusMessage "Failed to uninstall Scoop package '$($package.name)': $_" -Verbosity "Error"
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                continue
            }

            if ($LASTEXITCODE -ne 0 -or -not $result) {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            } else {
                Write-StatusMessage "[OK]" -ForegroundColor Green
                $packageCount++
            }
        }
    }

    Write-StatusMessage "- Scoop packages uninstallation completed! Processed $packageCount packages.`n" -ForegroundColor Green

    return $true
}