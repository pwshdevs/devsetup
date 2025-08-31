#Requires -Version 5.1

[CmdletBinding()]
param()

Function Write-StatusMessage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "Gray",
        [Parameter(Mandatory=$false)]
        [int]$Indent = 0,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Default", "Verbose", "Debug", "Warning", "Error")]
        [string]$Verbosity = "Default",
        [Parameter(Mandatory=$false)]
        [int]$Width = 0,
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine
    )

    if ($Indent -gt 0) {
        $Message = "$(' ' * $Indent)$Message"
    }

    if ($Width -gt 0) {
        if($Message.Length -gt $Width) {
            $Message = $Message.Substring(0, $Width - 3) + "...";
        } else {
            $Message = $Message.PadRight($Width, " ");
        }
    }

    $messageParams = @{ }

    if($Verbosity -eq "Default") {
        $messageParams.Object = $Message
        $messageParams.ForegroundColor = $ForegroundColor
        $messageParams.NoNewLine = $NoNewLine.IsPresent
    } else {
        $messageParams.Message = $Message
    }
    #$messageParams.Object = $Message

    switch($Verbosity) {
        "Verbose" {
            Write-Verbose @messageParams
        }
        "Debug" {
            Write-Debug @messageParams
        }
        "Warning" {
            Write-Warning @messageParams
        }
        "Error" {
            Write-Error @messageParams
        }
        "Default" {
            Write-Host @messageParams
        }
    }
}

function Center-Text($text, $width) {
    $text = "$text"
    $pad = $width - $text.Length
    if ($pad -le 0) { return $text }
    $left = [math]::Floor($pad / 2)
    $right = $pad - $left
    (' ' * $left) + $text + (' ' * $right)
}   

function Left-Text($text, $width) {
    $text = " $text"
    if ($text.Length -ge $width) { return $text }
    return $text + (' ' * ($width - $text.Length))
}

function Right-Text($text, $width) {
    $text = "$text "
    if ($text.Length -ge $width) { return $text }
    return (' ' * ($width - $text.Length)) + $text
}

$successCheck = [char]0x2713

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

    # Get the PSModulePath environment variable
    $psModulePath = $Env:PSModulePath

    # Split the string into an array of individual paths using the platform-specific path separator
    $modulePaths = $psModulePath -split [System.IO.Path]::PathSeparator

    # Determine the correct user modules path based on env:PSModulePath
    $UserModulesPath = ($modulePaths | Select-Object -First 1)
    
    if (-not $UserModulesPath) {
        throw "Unable to determine user modules path for PowerShell version $($PSVersionTable.PSVersion)"
    }
    
    Write-Debug "Target user modules path: $UserModulesPath"
    
    # Show current PSModulePath for debugging
    Write-Debug "Current PSModulePath:"
    ($env:PSModulePath -split [IO.Path]::PathSeparator) | ForEach-Object { Write-Debug "  $_" }

    # Get the module version from the manifest
    $ModuleVersion = $null
    Write-Debug "Reading module version from manifest..."
    try {
        $ManifestData = Import-PowerShellDataFile -Path $ModuleManifest
        $ModuleVersion = $ManifestData.ModuleVersion
        if (-not $ModuleVersion) {
            throw "ModuleVersion not found in manifest"
        }
    } catch {
        Write-Warning "Failed to read module version from manifest: $_"
        Write-Host "Using default version: 1.0.0" -ForegroundColor Yellow
        $ModuleVersion = "1.0.0"
    }
    
    Write-Host "Installing DevSetup Module version: $ModuleVersion..." -ForegroundColor Yellow

    Write-StatusMessage "- Checking PowerShell Version..." -Width 60 -NoNewLine -ForegroundColor Gray
    Write-StatusMessage (Right-Text "[$($PSVersionTable.PSVersion)]" 20) -ForegroundColor Green
    Write-StatusMessage "- Checking PowerShell Edition..." -Width 60 -NoNewLine -ForegroundColor Gray 
    Write-StatusMessage (Right-Text "[$($PSVersionTable.PSEdition)]" 20) -ForegroundColor Green

    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -Force -ForceBootstrap
    
    Write-StatusMessage "- Installing NuGet Package Provider..." -Width 60 -NoNewLine -ForegroundColor Gray
    if ($nugetProvider) {
        Write-StatusMessage (Right-Text "[$($nugetProvider.Version)]" 20) -ForegroundColor Green
    } else {
        Install-PackageProvider -Name NuGet -Force -ForceBootstrap
        
        # Verify installation
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if ($nugetProvider) {
            Write-StatusMessage (Right-Text "[$($nugetProvider.Version)]" 20) -ForegroundColor Green
        } else {
            throw "Failed to install NuGet PackageProvider"
        }
    }

    # Install required module dependencies
    try {
        $RequiredModules = $ManifestData.RequiredModules
        if ($RequiredModules -and $RequiredModules.Count -gt 0) {
            foreach ($RequiredModule in $RequiredModules) {
                Write-StatusMessage "- Installing powershell dependency $RequiredModule..." -Width 60 -NoNewLine -ForegroundColor Gray
                # Check if the module is already installed
                $InstalledModule = Get-Module -ListAvailable -Name $RequiredModule -ErrorAction SilentlyContinue
                if ($InstalledModule) {
                    Write-StatusMessage (Right-Text "[$($InstalledModule[0].Version)]" 20) -ForegroundColor Green
                } else {
                    try {
                        Install-Module -Name $RequiredModule -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                        $InstalledModule = Get-Module -ListAvailable -Name $RequiredModule -ErrorAction SilentlyContinue
                        Write-StatusMessage (Right-Text "[$($InstalledModule[0].Version)]" 20) -ForegroundColor Green
                    } catch {
                        Write-StatusMessage (Right-Text "[FAILED]" 20) -ForegroundColor Red
                    }
                }
            }
        } else {
            Write-StatusMessage "- No required modules specified in manifest..." -Width 60 -NoNewLine -ForegroundColor Gray
            Write-StatusMessage (Right-Text "[$successCheck]" 20) -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to process required modules from manifest: $_"
        Write-Host "- Continuing with installation..." -ForegroundColor Gray
    }
    
    # Create the user modules directory if it doesn't exist
    if (-not (Test-Path $UserModulesPath)) {
        Write-StatusMessage "- Creating user modules directory..." -Width 60 -NoNewLine -ForegroundColor Gray
        New-Item -Path $UserModulesPath -ItemType Directory -Force | Out-Null
        Write-StatusMessage (Right-Text "[$successCheck]" 20) -ForegroundColor Green
    }
    
    # Define the target installation path with version
    $TargetModuleBasePath = Join-Path -Path $UserModulesPath -ChildPath "DevSetup"
    $TargetModulePath = Join-Path -Path $TargetModuleBasePath -ChildPath $ModuleVersion
    
    # Remove existing installation if it exists
    if (Test-Path $TargetModuleBasePath) {
        Write-StatusMessage "- Removing existing DevSetup module versions..." -Width 60 -NoNewLine -ForegroundColor Gray
        Remove-Item -Path $TargetModuleBasePath -Recurse -Force | Out-Null
        Write-StatusMessage (Right-Text "[$successCheck]" 20) -ForegroundColor Green
    }
    
    # Create the versioned directory structure
    Write-StatusMessage "- Creating versioned directory structure..." -Width 60 -NoNewLine -ForegroundColor Gray
    New-Item -Path $TargetModulePath -ItemType Directory -Force | Out-Null
    Write-StatusMessage (Right-Text "[$successCheck]" 20) -ForegroundColor Green
    
    # Copy the DevSetup module contents to the versioned path
    Write-StatusMessage "- Installing DevSetup module..." -Width 60 -NoNewLine -ForegroundColor Gray
    Copy-Item -Path "$DevSetupModulePath\*" -Destination $TargetModulePath -Recurse -Force | Out-Null
    Write-StatusMessage (Right-Text "[$successCheck]" 20) -ForegroundColor Green

    # Verify the installation
    Write-StatusMessage "- Verifying installation..." -Width 60 -NoNewLine -ForegroundColor Gray
    
    # Check if the module is now in PSModulePath
    $ModuleFound = Get-Module -ListAvailable -Name "DevSetup" -ErrorAction SilentlyContinue
    if ($ModuleFound) {
        #Write-Host "- Installation Verified..." -ForegroundColor Gray
        Write-StatusMessage (Right-Text "[$successCheck]" 20) -ForegroundColor Green
        $ModuleFound | ForEach-Object {
            Write-Debug "  - Version: $($_.Version) at $($_.ModuleBase)"
        }
    } else {
        Write-StatusMessage (Right-Text "[FAILED]" 20) -ForegroundColor Red
        Write-Warning "DevSetup module not found in module search paths!"
        Write-Host "- Manual verification - checking installation path..." -ForegroundColor Yellow
        if (Test-Path (Join-Path $TargetModulePath "DevSetup.psd1")) {
            Write-Host " - Module files exist at target path: $TargetModulePath" -ForegroundColor Green
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
    #Write-Host "Install Path:`n- $TargetModulePath`n" -ForegroundColor Gray
    Write-Host "You can now use DevSetup commands in any PowerShell session." -ForegroundColor White
    
    # Add the module to the current session's auto-import
    Write-Debug "`nSetting up module auto-import for current session..."
    if ($ModuleFound) {
        # Force import in current session
        Import-Module DevSetup -Force -Global
        Write-Debug "DevSetup module loaded in current session."
    }
    
    Write-Host "`nTo get started, run:" -ForegroundColor Cyan
    #Write-Host "  Use-DevSetup -Init" -ForegroundColor White
    #Write-Host "  # or use the alias:" -ForegroundColor Gray
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

Write-Host ""
#Write-Host "`nPress any key to continue..." -ForegroundColor Gray
#$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")