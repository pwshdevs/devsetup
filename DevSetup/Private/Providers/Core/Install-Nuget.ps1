<#
.SYNOPSIS
    Installs the NuGet PackageProvider for PowerShell package management.

.DESCRIPTION
    This function installs the NuGet PackageProvider which is required for PowerShell package management
    operations. It validates platform compatibility (Windows-only), administrator privileges, and existing
    installations before proceeding. The function also detects and reports on the availability of the
    NuGet CLI tool if present on the system.

.OUTPUTS
    [System.Boolean]
    Returns $true if NuGet PackageProvider is successfully installed or already exists.
    Returns $false if the installation fails or system requirements are not met.

.EXAMPLE
    Install-Nuget
    
    Installs the NuGet PackageProvider on the current system.

.EXAMPLE
    if (Install-Nuget) {
        Write-Host "NuGet PackageProvider is ready for use"
        # Proceed with PowerShell module installations
    } else {
        Write-Host "Failed to install NuGet PackageProvider"
        # Handle installation failure
    }
    
    Demonstrates conditional logic based on installation success.

.EXAMPLE
    $nugetReady = Install-Nuget
    if ($nugetReady) {
        Install-Module -Name SomeModule -Force
    }
    
    Shows using the function result to proceed with module operations.

.NOTES
    - Requires administrator privileges on Windows systems
    - Uses Test-RunningAsAdmin to validate privileges before proceeding
    - Throws an exception if not running as administrator
    - Windows-only functionality - automatically skips installation on non-Windows platforms
    - Installs minimum version 2.8.5.201 of the NuGet PackageProvider
    - Uses CurrentUser scope for installation to minimize system impact
    - Verifies successful installation by re-querying the PackageProvider
    - Detects and reports NuGet CLI availability if present
    - Uses -Force flag to bypass confirmation prompts
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Returns $true for successful installation or if already installed (idempotent behavior)

.LINK

.COMPONENT
    DevSetup.Providers.Core

.FUNCTIONALITY
    Package Management Setup, NuGet Installation, Prerequisites Management
#>

Function Install-Nuget {
    [CmdletBinding()]
    Param()
    
    try {
        # Check if we're on Windows - NuGet PackageProvider is Windows-only
        if (-not (Test-OperatingSystem -Windows)) {
            Write-Host "NuGet PackageProvider is not available on this platform. Skipping installation." -ForegroundColor Yellow
            return $true
        }
        
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "NuGet installation requires administrator privileges. Please run as administrator."
        }
        
        # Check if NuGet PackageProvider is installed
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        Write-StatusMessage "- Installing NuGet PackageProvider" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
        if ($nugetProvider) {
            #Write-Host "NuGet PackageProvider is already installed (version: $($nugetProvider.Version))" -ForegroundColor Green
            Write-StatusMessage "[OK]" -ForegroundColor Green
        } else {
            #Write-Host "Installing NuGet PackageProvider..." -ForegroundColor Cyan
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
            
            # Verify installation
            $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            if ($nugetProvider) {
                #Write-Host "NuGet PackageProvider successfully installed (version: $($nugetProvider.Version))" -ForegroundColor Green
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                throw "Failed to install NuGet PackageProvider"
            }
        }
        
        # Check if nuget.exe CLI is also available
        $nugetExe = Get-Command nuget -ErrorAction SilentlyContinue
        if ($nugetExe) {
            try {
                $nugetVersion = (Invoke-Expression "& nuget help" 2>$null | Select-String "NuGet Version" | ForEach-Object { $_.Line.Split(':')[1].Trim() })
                if ($nugetVersion) {
                    #Write-Host "NuGet CLI is also available: $nugetVersion" -ForegroundColor Yellow
                }
            }
            catch {
                # Silently ignore CLI version check errors
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Error checking/installing NuGet: $_"
        return $false
    }
}