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
    Export-InstalledScoopPackages -Config "environment.yaml"
    
    Exports installed Scoop packages to the existing environment.yaml configuration file.

.EXAMPLE
    Export-InstalledScoopPackages -Config "current.yaml" -OutFile "backup.yaml"
    
    Reads from current.yaml and saves the updated configuration with installed packages to backup.yaml.

.EXAMPLE
    Export-InstalledScoopPackages -Config "dev-env.yaml" -DryRun
    
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

Function Export-InstalledScoopPackage {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Config,
        [string]$OutFile,
        [switch]$DryRun
    )

    try {
        # Check if Scoop is installed
        if(-Not (Test-ScoopInstalled)) {
            Write-Warning "Scoop is not installed. Cannot check for components."
            return $false
        }

        $scoopCommand = Find-Scoop
        if (-not $scoopCommand) {
            Write-Warning "Failed to find Scoop command. Cannot check for components."
            return $false
        }

        # Get list of installed Scoop packages
        Write-Host "- Getting list of installed Scoop packages..." -ForegroundColor Gray
        
        # Get all packages (both local and global) using scoop export
        $scoopListLocal = ""
        
        try {
            # Use scoop export - it returns JSON with both local and global packages
            $command = "& '$scoopCommand' export"
            $scoopListLocal = Invoke-Expression $command 6>$null
            if (-not $scoopListLocal) {
                Write-Warning "No Scoop packages found or scoop export command failed."
                return $true
            }
        } catch {
            Write-Verbose "Could not get Scoop packages: $_"
        }

        # TODO: 
        # scoop kinda sucks, they do so many weird things, for instance scoop install helm works fine and produces what you'd expect
        # scoop install main/helm, totally kills what the source was in scoop list and provides a path to a json file
        # scoop install main/helm@3.17.4 is even worse, it provides <auto generated> for the source
        # in order to make sure we dont have problems with exported configurations we need to "look up" each package and see what bucket 
        # it actually belongs in while exporting so when someone imports it back in later, it provides a valid bucket to install from
        # scoop search '^helm$'

        $scoopPackages = @()
        $scoopBuckets = @()

        # Parse packages from scoop export JSON
        if ($scoopListLocal) {
            try {
                # Convert JSON output to PowerShell object
                $exportData = $scoopListLocal | ConvertFrom-Json
                
                # Parse buckets from the JSON structure
                if ($exportData.buckets -and $exportData.buckets.Count -gt 0) {
                    foreach ($bucket in $exportData.buckets) {
                        # Skip the 'main' bucket as it's automatically installed with Scoop
                        if ($bucket.Name -eq "main") {
                            Write-Debug "Skipping 'main' bucket (automatically installed with Scoop)"
                            continue
                        }
                        
                        $bucketInfo = @{
                            name = $bucket.Name
                            source = $bucket.Source
                        }
                        $scoopBuckets += $bucketInfo
                        Write-Debug "Found bucket: $($bucket.Name) (source: $($bucket.Source))"
                    }
                }
                
                # Parse apps from the JSON structure
                if ($exportData.apps -and $exportData.apps.Count -gt 0) {
                    foreach ($app in $exportData.apps) {
                        $packageName = $app.Name
                        $version = $app.Version
                        $bucket = $app.Source
                        
                        # Determine if this is a global install based on the Info field
                        $isGlobal = $app.Info -eq "Global install"
                        
                        Write-Debug "Found package from JSON export: $packageName (version: $version, bucket: $bucket, global: $isGlobal)"
                        $packageInfo = @{
                            name = $packageName
                            version = $version
                            global = $isGlobal
                        }
                        
                        # Always include bucket information for clarity
                        if ($bucket) {
                            $packageInfo.bucket = $bucket
                        }
                        
                        $scoopPackages += $packageInfo
                    }
                } else {
                    Write-Verbose "No apps found in scoop export JSON"
                }
            } catch {
                Write-Warning "Failed to parse scoop export JSON: $_"
                Write-Verbose "Raw export output: $scoopListLocal"
            }
        }

        if ($scoopPackages.Count -eq 0) {
            Write-Warning "No Scoop packages found."
            return $true
        }

        Write-Debug "Found $($scoopPackages.Count) Scoop packages and $($scoopBuckets.Count) buckets"

        # Read existing YAML configuration
        $YamlData = Read-ConfigurationFile -Config $Config

        # Ensure scoopPackages and scoopBuckets sections exist
        if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
        if (-not $YamlData.devsetup.dependencies) { $YamlData.devsetup.dependencies = @{} }
        if (-not $YamlData.devsetup.dependencies.scoop) { $YamlData.devsetup.dependencies.scoop = @{} }
        if (-not $YamlData.devsetup.dependencies.scoop.packages) { $YamlData.devsetup.dependencies.scoop.packages = @() }
        if (-not $YamlData.devsetup.dependencies.scoop.buckets) { $YamlData.devsetup.dependencies.scoop.buckets = @() }

        # Add buckets to YAML data first (packages may depend on these buckets)
        foreach ($bucket in $scoopBuckets) {
            # Check if bucket already exists
            $existingBucket = $YamlData.devsetup.dependencies.scoop.buckets | Where-Object {
                ($_ -is [string] -and $_ -eq $bucket.name) -or
                ($_ -is [hashtable] -and $_.name -eq $bucket.name)
            }

            if (-not $existingBucket) {
                Write-Host "  - Adding bucket: $($bucket.name) ($($bucket.source))" -ForegroundColor Gray
                
                # Create bucket object
                $bucketObj = @{
                    name = $bucket.name
                    source = $bucket.source
                }

                $YamlData.devsetup.dependencies.scoop.buckets += $bucketObj
            } else {
                # Bucket exists, check if source has changed
                $existingSource = $null
                
                if ($existingBucket -is [hashtable]) {
                    $existingSource = $existingBucket.source
                }

                if ($existingSource -and $existingSource -ne $bucket.source) {
                    Write-Host "    - Updating bucket: $($bucket.name) ($existingSource -> $($bucket.source))" -ForegroundColor Cyan
                    
                    # Find index and update
                    $index = $YamlData.devsetup.dependencies.scoop.buckets.IndexOf($existingBucket)

                    if ($existingBucket -is [string]) {
                        # Convert string to hashtable with source
                        $bucketObj = @{
                            name = $bucket.name
                            source = $bucket.source
                        }

                        $YamlData.devsetup.dependencies.scoop.buckets[$index] = $bucketObj
                    } else {
                        # Update existing hashtable
                        $YamlData.devsetup.dependencies.scoop.buckets[$index].source = $bucket.source
                    }
                } elseif (-not $existingSource) {
                    Write-Host "  - Updating bucket: $($bucket.name)" -ForegroundColor Yellow
                    
                    # Find index and add source
                    $index = $YamlData.devsetup.dependencies.scoop.buckets.IndexOf($existingBucket)
                    
                    if ($existingBucket -is [string]) {
                        # Convert string to hashtable with source
                        $bucketObj = @{
                            name = $bucket.name
                            source = $bucket.source
                        }

                        $YamlData.devsetup.dependencies.scoop.buckets[$index] = $bucketObj
                    } else {
                        # Add source to existing hashtable
                        $YamlData.devsetup.dependencies.scoop.buckets[$index].source = $bucket.source
                    }
                } else {
                    Write-Host "  - Skipping bucket (No Change): $($bucket.name) ($($bucket.source))" -ForegroundColor Gray
                }
            }
        }

        # Add packages to YAML data
        foreach ($package in $scoopPackages) {
            # Check if package already exists
            $existingPackage = $YamlData.devsetup.dependencies.scoop.packages | Where-Object {
                ($_ -is [string] -and $_ -eq $package.name) -or
                ($_ -is [hashtable] -and $_.name -eq $package.name)
            }

            if (-not $existingPackage) {
                Write-Host "  - Adding package: $($package.name) ($($package.version))" -ForegroundColor Gray
                
                # Create package object with all relevant properties
                $packageObj = @{
                    name = $package.name
                    version = $package.version
                }
                
                if ($package.bucket) {
                    $packageObj.bucket = $package.bucket
                }
                
                if ($package.global) {
                    $packageObj.global = $package.global
                }

                $YamlData.devsetup.dependencies.scoop.packages += $packageObj
            } else {
                # Package exists, check if version has changed
                $existingVersion = $null
                $existingGlobal = $false
                $existingBucket = $null
                
                if ($existingPackage -is [hashtable]) {
                    $existingVersion = $existingPackage.version
                    $existingGlobal = $existingPackage.global
                    $existingBucket = $existingPackage.bucket
                }

                if ($existingVersion -and $existingVersion -ne $package.version) {
                    Write-Host "    - Updating package: $($package.name) ($existingVersion -> $($package.version))" -ForegroundColor Cyan
                    
                    # Find index and update
                    $index = $YamlData.devsetup.dependencies.scoop.packages.IndexOf($existingPackage)

                    # Preserve existing package structure but update version
                    if ($existingPackage -is [string]) {
                        # Convert string to hashtable with version and other properties
                        $packageObj = @{
                            name = $package.name
                            version = $package.version
                        }
                        
                        if ($package.bucket) {
                            $packageObj.bucket = $package.bucket
                        }
                        
                        if ($package.global) {
                            $packageObj.global = $package.global
                        }
                        
                        $YamlData.devsetup.dependencies.scoop.packages[$index] = $packageObj
                    } else {
                        # Update existing hashtable
                        $YamlData.devsetup.dependencies.scoop.packages[$index].version = $package.version
                        
                        # Update bucket if changed
                        if ($package.bucket -and (-not $existingBucket -or $existingBucket -ne $package.bucket)) {
                            $YamlData.devsetup.dependencies.scoop.packages[$index].bucket = $package.bucket
                        }
                        
                        # Update global flag if changed
                        if ($package.global -ne $existingGlobal) {
                            $YamlData.devsetup.dependencies.scoop.packages[$index].global = $package.global
                        }
                    }
                } elseif (-not $existingVersion) {
                    Write-Host "  - Updating package: $($package.name)" -ForegroundColor Yellow
                    
                    # Find index and add version and other properties
                    $index = $YamlData.devsetup.dependencies.scoop.packages.IndexOf($existingPackage)
                    
                    if ($existingPackage -is [string]) {
                        # Convert string to hashtable with version and properties
                        $packageObj = @{
                            name = $package.name
                            version = $package.version
                        }
                        
                        if ($package.bucket) {
                            $packageObj.bucket = $package.bucket
                        }
                        
                        if ($package.global) {
                            $packageObj.global = $package.global
                        }
                        
                        $YamlData.devsetup.dependencies.scoop.packages[$index] = $packageObj
                    } else {
                        # Add version and other properties to existing hashtable
                        $YamlData.devsetup.dependencies.scoop.packages[$index].version = $package.version
                        
                        if ($package.bucket -and -not $existingBucket) {
                            $YamlData.devsetup.dependencies.scoop.packages[$index].bucket = $package.bucket
                        }
                        
                        if ($package.global -and -not $existingGlobal) {
                            $YamlData.devsetup.dependencies.scoop.packages[$index].global = $package.global
                        }
                    }
                } else {
                    Write-Host "  - Skipping package (No Change): $($package.name) ($($package.version))" -ForegroundColor Gray
                }
            }
        }

        # Convert to YAML
        try {
            $yamlOutput = $YamlData | ConvertTo-Yaml
        }
        catch {
            Write-Warning "Could not convert to YAML format. Showing PowerShell object instead:"
            $yamlOutput = $YamlData | ConvertTo-Json -Depth 10
        }

        # Handle output based on parameters
        if ($DryRun) {
            Write-Host "`nDry Run - Configuration would be saved as:" -ForegroundColor Cyan
            Write-Host $yamlOutput -ForegroundColor White
            Write-Host "`nNo files were modified (dry run mode)." -ForegroundColor Yellow
        } else {
            # Determine output file
            $outputFile = if ($OutFile) { $OutFile } else { $Config }

            try {
                Write-Debug "`nSaving configuration to: $outputFile"
                $yamlOutput | Out-File -FilePath $outputFile
                Write-Debug "Configuration saved successfully!"
            }
            catch {
                Write-Error "Failed to save configuration to $outputFile`: $_"
                return $false
            }
        }

        Write-Host "Scoop packages conversion completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error converting Scoop packages: $_"
        return $false
    }
}
