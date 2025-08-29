<#
.SYNOPSIS
    Lists available development environment configurations with platform filtering.

.DESCRIPTION
    This function displays all available development environment configurations in a formatted table.
    It supports platform-specific filtering to show only environments compatible with the current
    system or a specified platform. The function reads environment metadata from environments.json
    and automatically creates this index file if it doesn't exist using Optimize-DevSetupEnvs.
    Environments can be filtered by Windows, Linux, macOS, or shown for all platforms.

.PARAMETER Platform
    The platform to filter environments by.
    Valid values: "current", "all", "windows", "linux", "macos"
    Default value is "current" which shows environments for the detected platform.
    Use "all" to display environments regardless of platform compatibility.

.OUTPUTS
    [System.Boolean]
    Returns $true when the function completes successfully, regardless of whether environments are found.

.EXAMPLE
    Show-DevSetupEnvList
    
    Lists development environments compatible with the current platform.

.EXAMPLE
    Show-DevSetupEnvList -Platform "all"
    
    Displays all available development environments regardless of platform.

.EXAMPLE
    Show-DevSetupEnvList -Platform "linux"
    
    Shows only environments specifically designed for Linux systems.

.EXAMPLE
    Show-DevSetupEnvList -Platform "windows"
    
    Lists environments compatible with Windows systems.

.NOTES
    - Automatically detects the current platform using [System.Environment]::OSVersion.Platform
    - Maps platform detection: Win32NT → windows, Unix → linux/macos via uname command
    - Uses 'uname -s' command on Unix systems to distinguish between Linux (default) and macOS (Darwin)
    - Reads environment metadata from environments.json in the DevSetup directory
    - Automatically creates environments.json index if missing using Optimize-DevSetupEnvs
    - Recreates the index file if environments.json is corrupted or unreadable JSON
    - Supports cross-platform environments that work on multiple operating systems
    - Includes environments with empty/unspecified platform as compatible with all platforms
    - Platform filtering includes exact matches, "cross-platform" tagged environments, and unspecified platforms
    - Displays results in a formatted table showing Name, Version, Platform, and File columns
    - Shows "Not specified" for missing platform information and "Unknown" for missing version
    - Provides helpful guidance when no environments are found for the specified platform
    - Platform filtering and matching is case-insensitive for user convenience
    - Displays environment count summary after the table
    - Uses color-coded console output for better user experience

.LINK

.COMPONENT
    DevSetup.Commands

.FUNCTIONALITY
    Environment Discovery, Platform Detection, Configuration Listing
#>

Function Show-DevSetupEnvList {
    Param (
        [Parameter(Mandatory=$false, Position=0)]
        [ValidateSet("current", "all", "windows", "linux", "macos")]
        [string]$Platform = "current"  # Default to current platform
    )


    Write-Host "Listing available development environments..." -ForegroundColor Yellow

    # Determine the platform filter
    $platformFilter = $Platform.ToLower()
    if ($platformFilter -eq "current") {
        # Get current system platform
        if((Test-OperatingSystem -Windows)) {
            $platformFilter = "windows"
        } elseif((Test-OperatingSystem -Linux)) {
            $platformFilter = "linux"
        } elseif((Test-OperatingSystem -MacOS)) {
            $platformFilter = "macos"
        } else {
            $platformFilter = "windows"
        }
        Write-Host "Filtering for current platform: $platformFilter" -ForegroundColor Gray
    } elseif ($platformFilter -eq "all") {
        Write-Host "Showing all environments regardless of platform" -ForegroundColor Gray
    } else {
        Write-Host "Filtering for platform: $platformFilter" -ForegroundColor Gray
    }

    # Get the environments.json file path
    $devSetupPath = Get-DevSetupPath
    $environmentsJsonPath = Join-Path -Path $devSetupPath -ChildPath "environments.json"
    
    if (-not (Test-Path $environmentsJsonPath)) {
        Write-Host "No environments index found. Running optimization to create it..." -ForegroundColor Cyan
        Optimize-DevSetupEnvs | Out-Null
    } else {
        try {
            # Read the environments.json file
            $jsonContent = Get-Content -Path $environmentsJsonPath -Raw
            $environments = $jsonContent | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to read environments.json. Running optimization to recreate it..."
            Optimize-DevSetupEnvs | Out-Null
        }
    }
    
    # Filter environments by platform
    if ($platformFilter -ne "all") {
        $filteredEnvironments = @()
        foreach ($env in $environments) {
            $envPlatform = if ($env.platform) { $env.platform.ToLower() } else { "" }
            # Match exact platform or cross-platform environments
            if ($envPlatform -eq $platformFilter) {
                $filteredEnvironments += $env
            }
        }
        $environments = $filteredEnvironments
    }
    
    if ($environments.Count -eq 0) {
        if ($platformFilter -eq "all") {
            Write-Host "No development environments found." -ForegroundColor Yellow
        } else {
            Write-Host "No development environments found for platform: $platformFilter" -ForegroundColor Yellow
            Write-Host "Use -Platform 'all' to see all available environments." -ForegroundColor Gray
        }
        return $true
    }
    
    # Create a formatted table
    $tableData = @()
    foreach ($env in $environments) {
        $platformDisplay = if ($env.platform) { $env.platform } else { "Not specified" }
        $versionDisplay = if ($env.version) { $env.version } else { "Unknown" }
        $tableData += @{
            Name = $env.name
            Version = $versionDisplay
            Platform = $platformDisplay
            File = $env.file
            Provider = $env.provider
            Color = "DarkGray"
        }
    }
    
    $columnDefinitions = [ordered]@{
        Name     = @{ Name = "Name"; Width = 32; Alignment = "Left"; Color = "White"; Key = "Name" }
        Version  = @{ Name = "Version"; Width = 10; Alignment = "Center"; Color = "White"; Key = "Version" }
        Platform = @{ Name = "Platform"; Width = 15; Alignment = "Center"; Color = "White"; Key = "Platform" }
        Provider = @{ Name = "Provider"; Width = 15; Alignment = "Center"; Color = "White"; Key = "Provider" }
        File     = @{ Name = "File"; Width = 42; Alignment = "Left"; Color = "White"; Key = "File" }
    }

    $tableFormat = @{
        BorderColor = "DarkGray"
    }

    Format-PrettyTable -Columns $columnDefinitions -Rows $tableData -TableFormat $tableFormat

    Write-Host "Found $($environments.Count) environment(s)" -ForegroundColor Cyan
    Write-Host ""
}