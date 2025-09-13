<#
.SYNOPSIS
    Exports installed Scoop packages and buckets to a YAML configuration file.

.DESCRIPTION
    This function scans the system for installed Scoop packages and buckets, then exports them to a YAML 
    configuration file in DevSetup format. It uses 'scoop export' to retrieve comprehensive package information
    including versions, buckets, and global installation status. The function can update existing configuration
    files by merging new packages with existing ones, or create new configurations from scratch.

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
    Returns $true if the export completes successfully or if Scoop is not installed (skipped).
    Returns $false if there are errors during the export process.

.EXAMPLE
    Invoke-ScoopComponentExport -Config "environment.yaml"
    
    Exports installed Scoop packages to the existing environment.yaml configuration file.

.EXAMPLE
    Invoke-ScoopComponentExport -Config "current.yaml" -OutFile "backup.yaml"
    
    Reads from current.yaml and saves the updated configuration with installed packages to backup.yaml.

.EXAMPLE
    Invoke-ScoopComponentExport -Config "dev-env.yaml" -DryRun
    
    Shows what the configuration would look like without actually saving to file.

.NOTES
    - Requires Scoop to be installed on the system (gracefully skips if not found)
    - Uses 'scoop export' command to retrieve package and bucket information in JSON format
    - Handles both local and global package installations using Info field detection
    - Automatically skips the 'main' bucket as it's installed by default with Scoop
    - Merges with existing YAML configuration, preserving other sections and structure
    - Supports both simple string format and complex object format for packages and buckets
    - Updates existing packages/buckets when versions or sources have changed
    - Tracks global installation status and bucket information for each package
    - Provides detailed console output with color-coded status messages for all operations
    - Creates the devsetup.dependencies.scoop structure if it doesn't exist
    - Processes buckets before packages to ensure proper dependency order
    - Converts string entries to hashtable format when additional properties are needed
    - Preserves existing package properties while updating changed values
    - Includes comprehensive error handling for JSON parsing and file operations
    - Returns $true even when no packages are found (successful empty result)

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Configuration Export, Package Discovery, YAML Generation
#>

Function Invoke-ScoopComponentExport {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Config,
        [switch]$DryRun
    )

    try {
        # Check if Scoop is installed
        if(-Not (Test-ScoopInstalled)) {
            Write-StatusMessage "Scoop is not installed. Cannot check for components." -Verbosity Warning
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking Scoop installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $scoopCommand = Find-Scoop
        if (-not $scoopCommand) {
            Write-StatusMessage "Failed to find Scoop command. Cannot check for components." -Verbosity Warning
            return $false
        }
    } catch {
        Write-StatusMessage "Error finding Scoop command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    # Get list of installed Scoop packages
    Write-StatusMessage "- Getting list of installed Scoop packages..."
    
    # Get all packages (both local and global) using scoop export
    $scoopListLocal = $null

    try {
        $scoopPackageList = Get-ScoopPackagesAvailable
        if ($null -eq $scoopPackageList) {
            Write-StatusMessage "No Scoop packages found or unable to retrieve packages." -Verbosity Warning
            return $true
        }
    } catch {
        Write-StatusMessage "Could not get Scoop packages: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $scoopListLocal = Get-ScoopComponentsInstalled
        if ($null -eq $scoopListLocal) {
            Write-StatusMessage "No Scoop components found or unable to retrieve components." -Verbosity Warning
            return $true
        }
    } catch {
        Write-StatusMessage "Could not get Scoop components: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    $scoopPackages = @()
    $scoopBuckets = @()
        
    # Parse buckets from the JSON structure
    if ($scoopListLocal.buckets -and $scoopListLocal.buckets.Count -gt 0) {
        foreach ($bucket in $scoopListLocal.buckets) {
            # Skip the 'main' bucket as it's automatically installed with Scoop
            if ($bucket.Name -eq "main") {
                Write-StatusMessage "Skipping 'main' bucket (automatically installed with Scoop)" -Verbosity Debug
                continue
            }
            $scoopBuckets += @{
                name = $bucket.Name
                source = $bucket.Source
            }
            Write-StatusMessage "Found bucket: $($bucket.Name) (source: $($bucket.Source))" -Verbosity Debug
        }
    } else {
        Write-StatusMessage "No buckets found in scoop export JSON" -Verbosity Verbose
    }
    
    # Parse apps from the JSON structure
    if ($scoopListLocal.apps -and $scoopListLocal.apps.Count -gt 0) {
        foreach ($app in $scoopListLocal.apps) {
            $scoopPackages += @{
                name = $app.Name
                version = $app.Version
                global = ($app.Info -eq "Global install")
                bucket = $scoopPackageList[$app.Name].Source
            }
            Write-StatusMessage "Found package: $($app.Name) (version: $($app.Version), bucket: $($scoopPackageList[$app.Name].Source), global: $($app.Info -eq 'Global install'))" -Verbosity Debug
        }
    } else {
        Write-StatusMessage "No apps found in scoop export JSON" -Verbosity Verbose
    }

    if ($scoopPackages.Count -eq 0) {
        Write-StatusMessage "No Scoop packages found." -Verbosity Warning
        return $true
    }

    Write-StatusMessage "Found $($scoopPackages.Count) Scoop packages and $($scoopBuckets.Count) buckets" -Verbosity Debug

    $YamlData = Read-DevSetupEnvFile -Config $Config

    foreach ($bucket in $scoopBuckets) {
        $existingBucket = $YamlData.devsetup.dependencies.scoop.buckets | Where-Object {
            ($_.name -eq $bucket.name)
        }

        if (-not $existingBucket) {
            Write-StatusMessage "- Adding bucket: $($bucket.name) ($($bucket.source))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
            $YamlData.devsetup.dependencies.scoop.buckets += @{
                name = $bucket.name
                source = $bucket.source
            }
            Write-StatusMessage "[OK]" -ForegroundColor Green
        } else {
            $existingSource = $existingBucket.source
            if ($existingSource -and $existingSource -ne $bucket.source) {
                Write-StatusMessage "- Updating bucket: $($bucket.name) ($existingSource -> $($bucket.source))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
                $index = $YamlData.devsetup.dependencies.scoop.buckets.IndexOf($existingBucket)
                $YamlData.devsetup.dependencies.scoop.buckets[$index].source = $bucket.source
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "- Skipping bucket (No Change): $($bucket.name) ($($bucket.source))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
                Write-StatusMessage "[OK]" -ForegroundColor Green
            }
        }
    }

    # Add packages to YAML data
    foreach ($package in $scoopPackages) {
        # Check if package already exists
        $existingPackage = $YamlData.devsetup.dependencies.scoop.packages | Where-Object {
            ($_.name -eq $package.name)
        }

        if (-not $existingPackage) {
            Write-StatusMessage "- Adding package: $($package.name) ($($package.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
            
            # Create package object with all relevant properties
            $packageObj = @{
                name = $package.name
                version = $package.version
                bucket = $package.bucket
                global = $package.global
            }

            $YamlData.devsetup.dependencies.scoop.packages += $packageObj
            Write-StatusMessage "[OK]" -ForegroundColor Green
        } else {
            $existingVersion = $existingPackage.version
            $existingGlobal = $existingPackage.global
            $existingBucket = $existingPackage.bucket

            if (($existingVersion -and $existingVersion -ne $package.version) -or
                ($existingGlobal -and $existingGlobal -ne $package.global) -or
                ($existingBucket -and $existingBucket -ne $package.bucket)) {
                Write-StatusMessage "- Updating package: $($package.name) ($existingVersion -> $($package.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
                
                $index = $YamlData.devsetup.dependencies.scoop.packages.IndexOf($existingPackage)
                $YamlData.devsetup.dependencies.scoop.packages[$index] = @{
                    name = $package.name
                    version = $package.version
                    bucket = $package.bucket
                    global = $package.global
                }
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "- Skipping package (No Change): $($package.name) ($($package.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewLine
                Write-StatusMessage "[OK]" -ForegroundColor Green
            }
        }
    }

    try {
        Write-StatusMessage "`nSaving configuration to: $Config" -Verbosity Debug
        $YamlData | Update-DevSetupEnvFile -EnvFilePath $Config -WhatIf:$DryRun
        Write-StatusMessage "Configuration saved successfully!" -Verbosity Debug
    }
    catch {
        Write-StatusMessage "Failed to save configuration to $Config`: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    Write-StatusMessage "Scoop packages conversion completed!" -ForegroundColor Green
    return $true
}
