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
            Write-StatusMessage "Chocolatey is not available on this platform. Skipping installation." -Verbosity Error
            return $true
        }
    } catch {
        Write-StatusMessage "Error checking operating system: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
        
    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            Write-StatusMessage "Chocolatey installation requires administrator privileges. Please run as administrator." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking administrator privileges: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    Write-StatusMessage "- Installing Chocolatey package manager" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
    try {
        # Check if chocolatey is already installed
        if (Test-ChocolateyInstalled) {
            Write-StatusMessage "Chocolatey is already installed. Skipping installation." -Verbosity Debug
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-StatusMessage "Error checking Chocolatey installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
    
    try {
        # Set security protocols and execution policy
        Set-ExecutionPolicy Bypass -Scope Process -Force | Out-Null
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    
        # Download and install Chocolatey
        (Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) *> $null) *> $null
    } catch {
        Write-StatusMessage "Error during Chocolatey installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        Write-StatusMessage "[FAILED]" -ForegroundColor Red
        return $false
    }

    # Verify installation
    try {
        $chocoInstalled = Test-ChocolateyInstalled
        if ($chocoInstalled) {
            #Write-Host "Chocolatey successfully installed (version: $chocoVersion)!" -ForegroundColor Green
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        } else {
            Write-StatusMessage "[FAILD]" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-StatusMessage "Error verifying Chocolatey installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }  
}