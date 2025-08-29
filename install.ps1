#Requires -Version 5.1

[CmdletBinding()]
param()

Write-Host "DevSetup Module Installer" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

try {
    $ProgressPreference = 'SilentlyContinue'
    # Get the script directory (where the DevSetup module should be)
    $ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $DevSetupModulePath = Join-Path -Path $ScriptDirectory -ChildPath "DevSetup"

    Write-Debug "Script directory: $ScriptDirectory"
    Write-Debug "DevSetup module path: $DevSetupModulePath"

    # Verify the DevSetup module exists
    if (-not (Test-Path $DevSetupModulePath)) {
        throw "DevSetup module not found at: $DevSetupModulePath"
    }
    
    # Verify the module manifest exists
    $ModuleManifest = Join-Path -Path $DevSetupModulePath -ChildPath "DevSetup.psd1"
    if (-not (Test-Path $ModuleManifest)) {
        throw "DevSetup module manifest not found at: $ModuleManifest"
    }

    Write-Debug "DevSetup module found and verified."

    # Determine the correct user modules path based on PowerShell version
    $UserModulesPath = $null
    
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell 6+ (Core)
        # In PS 6+, $IsWindows, $IsLinux, $IsMacOS variables are available
        if ((Get-Variable -Name "IsWindows" -ErrorAction SilentlyContinue) -and $IsWindows) {
            # Windows
            $UserModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules"
        } elseif ((Get-Variable -Name "IsLinux" -ErrorAction SilentlyContinue) -and $IsLinux) {
            # Linux
            $UserModulesPath = Join-Path -Path $env:HOME -ChildPath ".local/share/powershell/Modules"
        } elseif ((Get-Variable -Name "IsMacOS" -ErrorAction SilentlyContinue) -and $IsMacOS) {
            # macOS
            $UserModulesPath = Join-Path -Path $env:HOME -ChildPath ".local/share/powershell/Modules"
        } else {
            # Fallback - assume Windows for PowerShell 6+ if platform detection fails
            $UserModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules"
        }
    } else {
        # PowerShell 5.1 (Windows PowerShell) - always Windows
        $UserModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
    }
    
    if (-not $UserModulesPath) {
        throw "Unable to determine user modules path for PowerShell version $($PSVersionTable.PSVersion)"
    }
    
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "PowerShell Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Yellow
    Write-Debug "Target user modules path: $UserModulesPath"
    
    # Show current PSModulePath for debugging
    Write-Debug "Current PSModulePath:"
    ($env:PSModulePath -split [IO.Path]::PathSeparator) | ForEach-Object { Write-Debug "  $_" }

    # Get the module version from the manifest
    Write-Debug "Reading module version from manifest..."
    try {
        $ManifestData = Import-PowerShellDataFile -Path $ModuleManifest
        $ModuleVersion = $ManifestData.ModuleVersion
        if (-not $ModuleVersion) {
            throw "ModuleVersion not found in manifest"
        }
        Write-Host "Installing DevSetup Module version: $ModuleVersion" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to read module version from manifest: $_"
        Write-Host "Using default version: 1.0.0" -ForegroundColor Yellow
        $ModuleVersion = "1.0.0"
    }
    
    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    
    if ($nugetProvider) {
        Write-Host "NuGet PackageProvider is already installed (version: $($nugetProvider.Version))" -ForegroundColor Green
    } else {
        Write-Host "Installing NuGet PackageProvider..." -ForegroundColor Cyan
        $env:__SuppressAutoNuGetProviderPrompt = 'true'
        $env:POWERSHELL_UPDATECHECK = 'Off'
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ForceBootstrap
        
        # Verify installation
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if ($nugetProvider) {
            Write-Host "NuGet PackageProvider successfully installed (version: $($nugetProvider.Version))" -ForegroundColor Green
        } else {
            throw "Failed to install NuGet PackageProvider"
        }
    }

    # Install required module dependencies
    Write-Host "Installing module dependencies..." -ForegroundColor Cyan
    try {
        $RequiredModules = $ManifestData.RequiredModules
        if ($RequiredModules -and $RequiredModules.Count -gt 0) {
            foreach ($RequiredModule in $RequiredModules) {
                Write-Host "- Checking dependency: $RequiredModule" -ForegroundColor Gray
                
                # Check if the module is already installed
                $InstalledModule = Get-Module -ListAvailable -Name $RequiredModule -ErrorAction SilentlyContinue
                if ($InstalledModule) {
                    Write-Host "  - Already installed: $RequiredModule (version: $($InstalledModule[0].Version))" -ForegroundColor Green
                } else {
                    Write-Host "  - Installing: $RequiredModule" -ForegroundColor Yellow
                    try {
                        Install-Module -Name $RequiredModule -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                        Write-Host "  - Successfully installed: $RequiredModule" -ForegroundColor Green
                    } catch {
                        Write-Warning "  - Failed to install $RequiredModule`: $_"
                        Write-Host "  - You may need to install this module manually later" -ForegroundColor Yellow
                    }
                }
            }
        } else {
            Write-Host "- No required modules specified in manifest" -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Failed to process required modules from manifest: $_"
        Write-Host "Continuing with installation..." -ForegroundColor Yellow
    }
    
    # Create the user modules directory if it doesn't exist
    if (-not (Test-Path $UserModulesPath)) {
        Write-Host "Creating user modules directory: $UserModulesPath" -ForegroundColor Cyan
        New-Item -Path $UserModulesPath -ItemType Directory -Force | Out-Null
    }
    
    # Define the target installation path with version
    $TargetModuleBasePath = Join-Path -Path $UserModulesPath -ChildPath "DevSetup"
    $TargetModulePath = Join-Path -Path $TargetModuleBasePath -ChildPath $ModuleVersion
    
    Write-Host "- Install Path: $TargetModulePath" -ForegroundColor Gray
    
    # Remove existing installation if it exists
    if (Test-Path $TargetModuleBasePath) {
        Write-Host "- Removing existing DevSetup module versions..." -ForegroundColor Gray
        Remove-Item -Path $TargetModuleBasePath -Recurse -Force | Out-Null
    }
    
    # Create the versioned directory structure
    Write-Host "- Creating versioned directory structure..." -ForegroundColor Gray
    New-Item -Path $TargetModulePath -ItemType Directory -Force | Out-Null
    
    # Copy the DevSetup module contents to the versioned path
    Write-Host "- Installing DevSetup module..." -ForegroundColor Gray
    Copy-Item -Path "$DevSetupModulePath\*" -Destination $TargetModulePath -Recurse -Force | Out-Null
    
    # Verify the installation
    Write-Host "- Verifying installation..." -ForegroundColor Gray
    
    # Check if the module is now in PSModulePath
    $ModuleFound = Get-Module -ListAvailable -Name "DevSetup" -ErrorAction SilentlyContinue
    if ($ModuleFound) {
        Write-Host "- Installation Verified..." -ForegroundColor Gray
        $ModuleFound | ForEach-Object {
            Write-Debug "  - Version: $($_.Version) at $($_.ModuleBase)"
        }
    } else {
        Write-Warning "DevSetup module not found in module search paths!"
        Write-Host "Manual verification - checking installation path..." -ForegroundColor Yellow
        if (Test-Path (Join-Path $TargetModulePath "DevSetup.psd1")) {
            Write-Host "Module files exist at target path: $TargetModulePath" -ForegroundColor Green
        } else {
            Write-Error "Module files not found at target path!"
        }
    }
    
    # Import the module to test it
    try {
        Import-Module -Name "DevSetup" -Force -ErrorAction Stop
        Write-Debug "DevSetup module imported successfully!"
        
        # Test a basic function
        if (Get-Command -Name "Use-DevSetup" -ErrorAction SilentlyContinue) {
            Write-Debug "DevSetup functions are available."
        } else {
            Write-Warning "DevSetup functions may not be properly loaded."
        }
        
        # Show module information
        $ModuleInfo = Get-Module -Name "DevSetup"
        if ($ModuleInfo) {
            Write-Debug "Module Version: $($ModuleInfo.Version)"
            Write-Debug "Module Path: $($ModuleInfo.ModuleBase)"
        }
        
    } catch {
        Write-Warning "Failed to import DevSetup module: $_"
    }
    
    Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
    Write-Host "You can now use DevSetup commands in any PowerShell session." -ForegroundColor White
    
    # Add the module to the current session's auto-import
    Write-Debug "`nSetting up module auto-import for current session..."
    if ($ModuleFound) {
        # Force import in current session
        Import-Module DevSetup -Force -Global
        Write-Debug "DevSetup module loaded in current session."
    }
    
    Write-Host "`nTo get started, try:" -ForegroundColor Cyan
    Write-Host "  Use-DevSetup -Init" -ForegroundColor White
    Write-Host "  # or use the alias:" -ForegroundColor Gray
    Write-Host "  devsetup -Init" -ForegroundColor White
    
    Write-Host "`nNote: If the command isn't found in new sessions, run:" -ForegroundColor Yellow
    Write-Host "  Import-Module DevSetup" -ForegroundColor White
    
} catch {
    Write-Error "Installation failed: $_"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure you're running this script from the DevSetup directory" -ForegroundColor White
    Write-Host "2. Check that the DevSetup folder and DevSetup.psd1 file exist" -ForegroundColor White
    Write-Host "3. Verify you have write permissions to the user modules directory" -ForegroundColor White
    exit 1
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")