<#
.SYNOPSIS
    Initializes the DevSetup environment and directory structure.

.DESCRIPTION
    This function sets up the complete DevSetup environment by installing core dependencies and creating
    the necessary directory structure. It performs a comprehensive initialization process including
    dependency validation, directory creation, and environment path setup. The function ensures all
    prerequisites are in place before DevSetup can be used for environment management operations.

.OUTPUTS
    [System.Boolean]
    Returns $true if the DevSetup environment is successfully initialized.
    Returns $false if initialization fails at any step.

.EXAMPLE
    Initialize-DevSetup
    
    Initializes the complete DevSetup environment with default settings.

.EXAMPLE
    if (Initialize-DevSetup) {
        Write-Host "DevSetup is ready for use"
        # Proceed with environment operations
    } else {
        Write-Host "DevSetup initialization failed"
        # Handle initialization failure
    }
    
    Demonstrates conditional logic based on initialization success.

.EXAMPLE
    $setupReady = Initialize-DevSetup
    if ($setupReady) {
        Use-DevSetup -List
    }
    
    Shows using the function result to proceed with DevSetup operations.

.NOTES
    - This should be the first function called when setting up DevSetup
    - Performs initialization in a specific sequence:
      1. Installs core dependencies via Install-CoreDependencies
      2. Creates the main .devsetup directory using Get-DevSetupPath
      3. Initializes the environments directory via Initialize-DevSetupEnvs
    - Uses fail-fast approach - stops immediately if core dependencies cannot be installed
    - Creates the .devsetup directory in the user's home directory if it doesn't exist
    - Uses -Force flag for directory creation to handle any permission issues
    - Suppresses directory creation output using Out-Null for clean console experience
    - Provides verbose logging when .devsetup directory already exists
    - Validates each initialization step and returns appropriate success/failure status
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Color-coded console output for different phases: Cyan for progress, Green for success

.LINK

.COMPONENT
    DevSetup.Commands

.FUNCTIONALITY
    Environment Setup, Directory Management, Dependency Installation
#>

Function Initialize-DevSetup {
    try {  
        # Install core dependencies first
        Write-Host "- Installing core dependencies..." -ForegroundColor Cyan
        if (-not (Install-CoreDependencies)) {
            Write-Error "Failed to install core dependencies"
            return
        }
        Write-Host "- Core dependencies installed successfully" -ForegroundColor Green        
        
        # Define .devsetup folder path
        $devSetupPath = Get-DevSetupPath
        
        # Check if .devsetup folder exists
        if (-not (Test-Path -Path $devSetupPath)) {
            #Write-Host "Creating .devsetup directory at: $devSetupPath" -ForegroundColor Cyan
            New-Item -Path $devSetupPath -ItemType Directory -Force | Out-Null
            #Write-Host ".devsetup directory created successfully" -ForegroundColor Green
        } else {
            Write-Verbose ".devsetup directory already exists at: $devSetupPath"
        }

        Write-Host ""
        Write-Host "- Installing community environments..." -ForegroundColor Cyan
        # Initialize DevSetup environments path
        $envSetupPath = Initialize-DevSetupEnvs
        if (-not $envSetupPath) {
            Write-Error "Failed to initialize DevSetup environment path"
            return $false
        } else {
            Write-Host "- Community environments installed successfully" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Path Information: " -ForegroundColor Yellow
        Write-Host "- DevSetup:" -ForegroundColor Cyan
        Write-Host "  - $devSetupPath" -ForegroundColor Gray
        Write-Host "- Local Environments: " -ForegroundColor Cyan
        Write-Host "  - $($envSetupPath.Local)" -ForegroundColor Gray
        Write-Host "- Community Environments: " -ForegroundColor Cyan
        Write-Host "  - $($envSetupPath.Community)" -ForegroundColor Gray        
        Write-Host ""

        # Return the path for use by other functions
        return $true
    }
    catch {
        Write-Error "Failed to initialize DevSetup environment: $_"
        return $false
    }
}