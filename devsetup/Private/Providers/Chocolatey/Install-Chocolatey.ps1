<#
.SYNOPSIS
    Installs Chocolatey package manager on Windows systems.

.DESCRIPTION
    This function installs the Chocolatey package manager by downloading and executing the official
    installation script from the Chocolatey website. It includes comprehensive validation for platform
    compatibility, administrator privileges, and existing installations. The function handles security
    protocol configuration and execution policy adjustments required for the installation process.

.OUTPUTS
    [System.Boolean]
    Returns $true if Chocolatey is successfully installed or already exists.
    Returns $false if the installation fails or system requirements are not met.

.EXAMPLE
    Install-Chocolatey
    
    Installs Chocolatey package manager on the current system.

.EXAMPLE
    if (Install-Chocolatey) {
        Write-Host "Chocolatey is ready for use"
        # Proceed with package installations
    } else {
        Write-Host "Failed to install Chocolatey"
        # Handle installation failure
    }
    
    Demonstrates conditional logic based on installation success.

.EXAMPLE
    $chocoReady = Install-Chocolatey
    if ($chocoReady) {
        choco install git -y
    }
    
    Shows using the function result to proceed with package operations.

.NOTES
    - Requires administrator privileges on Windows systems
    - Uses Test-RunningAsAdmin to validate privileges before proceeding
    - Automatically skips installation on non-Windows platforms (returns $true)
    - Checks for existing Chocolatey installation before attempting download
    - Sets execution policy to Bypass for the current process scope during installation
    - Configures TLS 1.2 security protocol for secure download
    - Downloads installation script from https://community.chocolatey.org/install.ps1
    - Verifies successful installation by checking for 'choco' command availability
    - Displays version information after successful installation
    - Uses comprehensive try-catch error handling with descriptive error messages
    - Suppresses command output using Out-Null to avoid console clutter
    - Returns $true even if Chocolatey is already installed (idempotent behavior)

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Package Manager Installation, System Setup, Prerequisites Management
#>

Function Install-Chocolatey {
    [CmdletBinding()]
    Param()
    
    try {
        # Check if we're on Windows - Chocolatey is Windows-only
        if (-not (Test-OperatingSystem -Windows)) {
            Write-Host "Chocolatey is not available on this platform. Skipping installation." -ForegroundColor Yellow
            return $true
        }
        
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "Chocolatey installation requires administrator privileges. Please run as administrator."
        }
        
        Write-StatusMessage "- Installing Chocolatey package manager" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
        # Check if chocolatey is installed by testing the command
        $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
        
        if ($chocoInstalled) {
            $chocoVersion = Invoke-Expression "& choco --version" 2>$null
            #Write-Host "Chocolatey is already installed (version: $chocoVersion)" -ForegroundColor Green
            Write-StatusMessage "[OK]" -ForegroundColor Green
        } else {
            #Write-Host "Chocolatey not found. Installing Chocolatey..." -ForegroundColor Cyan
            
            # Set security protocols and execution policy
            Set-ExecutionPolicy Bypass -Scope Process -Force | Out-Null
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            
            # Download and install Chocolatey
            (Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) *> $null) *> $null
            
            # Verify installation
            $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
            if ($chocoInstalled) {
                $chocoVersion = Invoke-Expression "& choco --version" 2>$null
                #Write-Host "Chocolatey successfully installed (version: $chocoVersion)!" -ForegroundColor Green
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                throw "Failed to install Chocolatey"
            }
        }
        return $true
    }
    catch {
        Write-Error "Error checking/installing Chocolatey: $_"
        return $false
    }    
}