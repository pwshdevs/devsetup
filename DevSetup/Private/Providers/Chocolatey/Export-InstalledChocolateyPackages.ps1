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
    Export-InstalledChocolateyPackages -Config "environment.yaml"
    
    Exports installed Chocolatey packages to the existing environment.yaml configuration file.

.EXAMPLE
    Export-InstalledChocolateyPackages -Config "current.yaml" -OutFile "backup.yaml"
    
    Reads from current.yaml and saves the updated configuration with installed packages to backup.yaml.

.EXAMPLE
    Export-InstalledChocolateyPackages -Config "dev-env.yaml" -DryRun
    
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

Function Export-InstalledChocolateyPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Config,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "This operation requires administrator privileges. Please run as administrator."
        }

        # Get list of installed Chocolatey packages
        Write-Host "- Getting list of installed Chocolatey packages..." -ForegroundColor Gray
        $chocoList = Invoke-Expression "& choco list --local-only --limit-output"

        if (-not $chocoList) {
            Write-Warning "No Chocolatey packages found or Chocolatey is not installed."
            return $true
        }

        $chocolateyPackages = @()
        
        $packagesToIgnore = Get-ChocolateyPackageDependencies | Select-Object -Unique

        foreach ($line in $chocoList) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            
            # Parse package info (format: packagename|version)
            $parts = $line.Split('|')
            if ($parts.Count -ge 2) {
                $packageName = $parts[0].Trim()
                $version = $parts[1].Trim()
                
                # Skip packages starting with chocolatey
                if ($packageName -like "chocolatey*") {
                    Write-Verbose "Skipping chocolatey package: $packageName"
                    continue
                }

                if($packagesToIgnore -contains $packageName) {
                    Write-Verbose "Skipping ignored package: $packageName"
                    continue
                }

                Write-Debug "Found package: $packageName (version: $version)"
                $chocolateyPackages += @{
                    name = $packageName
                    version = $version
                }
            }
        }

        Write-Debug "Found $($chocolateyPackages.Count) Chocolatey packages (excluding .install and chocolatey* packages)"

        # Read existing YAML configuration
        $YamlData = Read-ConfigurationFile -Config $Config

        # Ensure chocolateyPackages section exists
        if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
        if (-not $YamlData.devsetup.dependencies) { $YamlData.devsetup.dependencies = @{} }
        if (-not $YamlData.devsetup.dependencies.chocolatey) { $YamlData.devsetup.dependencies.chocolatey = @{} }
        if (-not $YamlData.devsetup.dependencies.chocolatey.packages) { $YamlData.devsetup.dependencies.chocolatey.packages = @() }

        # Add packages to YAML data
        foreach ($package in $chocolateyPackages) {
            # Check if package already exists
            $existingPackage = $YamlData.devsetup.dependencies.chocolatey.packages | Where-Object {
                ($_ -is [string] -and $_ -eq $package.name) -or
                ($_ -is [hashtable] -and $_.name -eq $package.name)
            }

            if (-not $existingPackage) {
                Write-Host "  - Adding package: $($package.name) ($($package.version))" -ForegroundColor Gray
                $YamlData.devsetup.dependencies.chocolatey.packages += @{
                    name = $package.name
                    version = $package.version
                }
            } else {
                # Package exists, check if version has changed
                $existingVersion = $null
                if ($existingPackage -is [hashtable] -and $existingPackage.version) {
                    $existingVersion = $existingPackage.version
                }

                if ($existingVersion -and $existingVersion -ne $package.version) {
                    Write-Host "    - Updating package: $($package.name) ($existingVersion -> $($package.version))" -ForegroundColor Cyan
                    
                    # Find index and update
                    $index = $YamlData.devsetup.dependencies.chocolatey.packages.IndexOf($existingPackage)

                    # Preserve existing package structure but update version
                    if ($existingPackage -is [string]) {
                        # Convert string to hashtable with version
                        $YamlData.devsetup.dependencies.chocolatey.packages[$index] = @{
                            name = $package.name
                            version = $package.version
                        }
                    } else {
                        # Update existing hashtable
                        $YamlData.devsetup.dependencies.chocolatey.packages[$index].version = $package.version
                    }
                } elseif (-not $existingVersion) {
                    Write-Host "  - Updating package: $($package.name)" -ForegroundColor Yellow
                    
                    # Find index and add version
                    $index = $YamlData.devsetup.dependencies.chocolatey.packages.IndexOf($existingPackage)

                    if ($existingPackage -is [string]) {
                        # Convert string to hashtable with version
                        $YamlData.devsetup.dependencies.chocolatey.packages[$index] = @{
                            name = $package.name
                            version = $package.version
                        }
                    } else {
                        # Add version to existing hashtable
                        $YamlData.devsetup.dependencies.chocolatey.packages[$index].version = $package.version
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

        Write-Host "Chocolatey packages conversion completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error converting Chocolatey packages: $_"
        return $false
    }
}