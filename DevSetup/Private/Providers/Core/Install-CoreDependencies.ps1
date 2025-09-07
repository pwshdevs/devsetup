<#
.SYNOPSIS
    Installs core dependencies required for the DevSetup module to function properly.

.DESCRIPTION
    This function installs essential system dependencies and package managers required for DevSetup operations.
    It sequentially installs NuGet PackageProvider, required PowerShell modules from the DevSetup manifest,
    and platform-specific tools. On Windows, it also installs Chocolatey, Git, and Scoop. The function 
    validates each installation step and fails fast if any critical component cannot be installed. It also 
    refreshes the PATH environment variable to ensure newly installed tools are immediately available.

.OUTPUTS
    [System.Boolean]
    Returns $true if all core dependencies are successfully installed.
    Returns $false if any critical installation fails.

.EXAMPLE
    Install-CoreDependencies
    
    Installs all core dependencies required for DevSetup functionality.

.EXAMPLE
    if (Install-CoreDependencies) {
        Write-Host "DevSetup is ready for use"
        # Proceed with environment setup
    } else {
        Write-Host "Failed to install core dependencies"
        # Handle installation failure
    }
    
    Demonstrates conditional logic based on installation success.

.EXAMPLE
    $coreReady = Install-CoreDependencies
    if ($coreReady) {
        # Continue with package installations
        Install-ChocolateyPackages -YamlData $config
    }
    
    Shows using the function result to proceed with subsequent operations.

.NOTES
    - Cross-platform support with platform detection using $IsWindows, $IsLinux, $IsMacOS
    - Sets up platform variables if not defined ($IsWindows = $true, others = $false by default)
    - Installs dependencies in a specific order to ensure proper functionality:
      1. NuGet PackageProvider (all platforms)
      2. Required PowerShell modules from DevSetup manifest (all platforms)
      3. Windows-only components:
         - Chocolatey package manager
         - Git version control system via Chocolatey
         - Scoop package manager
    - Uses fail-fast approach - stops immediately if any critical component fails
    - Installs PowerShell modules with -Force, -AllowClobber, and CurrentUser scope
    - Refreshes PATH environment variable after Git installation for immediate availability
    - Gets required modules list from Get-DevSetupManifest
    - Provides color-coded console output for installation progress
    - Skips empty module names in the manifest gracefully
    - Returns $true even if no required modules are found (considered success)
    - Windows-specific installations are conditionally executed based on platform detection

.LINK

.COMPONENT
    DevSetup.Providers.Core

.FUNCTIONALITY
    System Setup, Dependency Management, Package Manager Installation
#>

Function Install-CoreDependency {
    [CmdletBinding()]
    Param()

    # Install NuGet PackageProvider
    if ((Test-OperatingSystem -Windows)) {
        if (-not (Install-NuGet)) {
            Write-StatusMessage "Failed to install NuGet PackageProvider" -Verbosity Error
            return $false
        }
    }

    # Get required modules from DevSetup manifest
    $manifest = Get-DevSetupManifest
    if (-not $manifest -or -not $manifest.RequiredModules) {
        Write-StatusMessage "No required modules found in DevSetup manifest" -Verbosity Warning
        return $true
    }
    
    # Install each required PowerShell module
    foreach ($moduleName in $manifest.RequiredModules) {
        if (-not $moduleName -or [string]::IsNullOrEmpty($moduleName)) {
            Write-StatusMessage "Skipping empty module name" -Verbosity Warning
            continue
        }
        
        Write-StatusMessage "- Installing powershell module: $moduleName" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
        if (-not (Install-PowerShellModule -ModuleName $moduleName -Force -AllowClobber -Scope 'CurrentUser')) {
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            Write-StatusMessage "Failed to install required PowerShell module: $moduleName" -Verbosity Error
            return $false
        }
        Write-StatusMessage "[OK]" -ForegroundColor Green
    }

    if ((Test-OperatingSystem -Windows)) {
        # Install Chocolatey first
        if (-not (Install-Chocolatey)) {
            Write-StatusMessage "Cannot proceed without Chocolatey" -Verbosity Error
            return $false
        }   

        # Install Git using Chocolatey
        Write-StatusMessage "- Installing Git package via Chocolatey" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
        if (-not (Install-ChocolateyPackage -PackageName "git" -Version 2.50.1)) {
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            Write-StatusMessage "Failed to install Git package" -Verbosity Error
            return $false
        } else {
            Write-StatusMessage "[OK]" -ForegroundColor Green
        }

        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

        # Install Scoop PackageProvider
        if (-not (Install-Scoop)) {
            Write-StatusMessage "Failed to install Scoop PackageProvider" -Verbosity Error
            return $false
        } 
    } else {
        if (-not (Install-Homebrew)) {
            Write-StatusMessage "Failed to install Homebrew" -Verbosity Error
            return $false
        }
    }

    return $true
}