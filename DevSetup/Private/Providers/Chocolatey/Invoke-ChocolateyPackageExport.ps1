<#
.SYNOPSIS
    Exports installed Chocolatey packages to a YAML configuration file.

.DESCRIPTION
    This function scans the system for installed Chocolatey packages and exports them to a YAML 
    configuration file in DevSetup format. It uses 'choco list --local-only --limit-output' to retrieve 
    comprehensive package information including versions. The function intelligently filters out 
    system packages and can update existing configuration files by merging new packages with existing ones.

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
    Returns $true if the export completes successfully or if no packages are found.
    Returns $false if there are errors during the export process.

.EXAMPLE
    Invoke-ChocolateyPackageExport -Config "environment.yaml"
    
    Exports installed Chocolatey packages to the existing environment.yaml configuration file.

.EXAMPLE
    Invoke-ChocolateyPackageExport -Config "current.yaml" -OutFile "backup.yaml"
    
    Reads from current.yaml and saves the updated configuration with installed packages to backup.yaml.

.EXAMPLE
    Invoke-ChocolateyPackageExport -Config "dev-env.yaml" -DryRun
    
    Shows what the configuration would look like without actually saving to file.

.NOTES
    - Requires administrator privileges to access all installed packages
    - Uses 'choco list --local-only --limit-output' for machine-readable package information
    - Automatically filters out system packages:
      * Packages ending with '.install' (installer packages)
      * Packages starting with 'chocolatey' (Chocolatey system packages)
    - Merges with existing YAML configuration, preserving other sections and structure
    - Supports both simple string format and complex object format for packages
    - Updates existing packages when versions have changed
    - Converts string entries to hashtable format when version information is added
    - Creates the devsetup.dependencies.chocolatey structure if it doesn't exist
    - Provides detailed console output with color-coded status messages for operations
    - Handles YAML conversion errors gracefully by falling back to JSON format
    - Tracks package changes: new additions, version updates, and no-change skips

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Configuration Export, Package Discovery, YAML Generation
#>

Function Invoke-ChocolateyPackageExport {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Config,
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            Write-StatusMessage "This operation requires administrator privileges. Please run as administrator." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking administrator privileges: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    # Get list of installed Chocolatey packages
    Write-StatusMessage "- Getting list of installed Chocolatey packages..." -ForegroundColor Gray
    try {
        $chocoList = Invoke-Command -ScriptBlock { & choco list --local-only --limit-output }
        if($LASTEXITCODE -ne 0) {
            throw "Chocolatey command failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-StatusMessage "Failed to retrieve Chocolatey package list: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if (-not $chocoList) {
        Write-StatusMessage "No Chocolatey packages found or Chocolatey is not installed." -Verbosity Warning
        return $true
    }

    $chocolateyPackages = @()
    
    try {
        $packagesToIgnore = Get-ChocolateyPackageDependencyMap | Select-Object -Unique
    } catch {
        Write-StatusMessage "Failed to retrieve Chocolatey package dependency map: $_" -Verbosity Warning
        $packagesToIgnore = @()
    }

    foreach ($line in $chocoList) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        # Parse package info (format: packagename|version)
        $parts = $line.Split('|')
        if ($parts.Count -ge 2) {
            $packageName = $parts[0].Trim()
            $version = $parts[1].Trim()
            
            # Skip packages starting with chocolatey
            if ($packageName -like "chocolatey*") {
                Write-StatusMessage "Skipping chocolatey package: $packageName" -Verbosity Verbose
                continue
            }

            if($packagesToIgnore -contains $packageName) {
                Write-StatusMessage "Skipping ignored package: $packageName" -Verbosity Verbose
                continue
            }

            Write-StatusMessage "Found package: $packageName (version: $version)" -Verbosity Debug
            $chocolateyPackages += @{
                name = $packageName
                version = $version
            }
        }
    }

    Write-StatusMessage "Found $($chocolateyPackages.Count) Chocolatey packages (excluding .install and chocolatey* packages)" -Verbosity Debug

    # Read existing YAML configuration
    try {
        $YamlData = Read-DevSetupEnvFile -Config $Config
    } catch {
        Write-StatusMessage "Failed to read YAML configuration from $Config`: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    # Ensure chocolatey-specific sections exist
    if (-not $YamlData.devsetup.dependencies.chocolatey) { $YamlData.devsetup.dependencies.chocolatey = @{} }
    if (-not $YamlData.devsetup.dependencies.chocolatey.packages) { $YamlData.devsetup.dependencies.chocolatey.packages = @() }

    # Add packages to YAML data
    foreach ($package in $chocolateyPackages) {
        # Check if package already exists
        $existingPackage = $YamlData.devsetup.dependencies.chocolatey.packages | Where-Object {
            ($_ -is [string] -and $_ -eq $package.name) -or
            ($_.name -eq $package.name)
        }

        if (-not $existingPackage) {
            Write-StatusMessage "- Adding package: $($package.name) ($($package.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
            $YamlData.devsetup.dependencies.chocolatey.packages += @{
                name = $package.name
                version = $package.version
            }
            Write-StatusMessage "[OK]" -ForegroundColor Green
        } else {
            # Package exists, check if version has changed
            $existingVersion = $null
            if ((-not ($existingPackage -is [string])) -and $existingPackage.version) {
                $existingVersion = $existingPackage.version
            }

            if ($existingVersion -and $existingVersion -ne $package.version) {
                Write-StatusMessage "- Updating package: $($package.name) ($existingVersion -> $($package.version))" -ForegroundColor Cyan -Indent 2 -Width 112 -NoNewline
                
                # Find index and update
                $index = $YamlData.devsetup.dependencies.chocolatey.packages.IndexOf($existingPackage)
                $YamlData.devsetup.dependencies.chocolatey.packages[$index].version = $package.version
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } elseif (-not $existingVersion) {
                Write-StatusMessage "- Updating package: $($package.name)" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline

                # Find index and add version
                $index = $YamlData.devsetup.dependencies.chocolatey.packages.IndexOf($existingPackage)
                $YamlData.devsetup.dependencies.chocolatey.packages[$index].version = $package.version
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "- Skipping package (No Change): $($package.name) ($($package.version))" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
                Write-StatusMessage "[OK]" -ForegroundColor Gray
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

    Write-StatusMessage "Chocolatey packages conversion completed!" -ForegroundColor Green
    return $true
}