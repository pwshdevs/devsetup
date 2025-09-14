<#
.SYNOPSIS
    Installs a Chocolatey package with optional version and parameter specification.

.DESCRIPTION
    This function installs a Chocolatey package using the 'choco install' command with comprehensive
    validation and conflict resolution. It checks for existing installations, handles version conflicts
    by reinstalling when necessary, and validates administrator privileges before proceeding. The function
    supports custom installation parameters and provides detailed error handling throughout the process.

.PARAMETER PackageName
    The name of the Chocolatey package to install.
    This parameter is mandatory and must be a valid, non-empty string representing a Chocolatey package name.

.PARAMETER Version
    The specific version of the package to install.
    Optional parameter that specifies the exact version required. If not provided, the latest version is installed.

.PARAMETER Param
    Custom installation parameters to pass to the Chocolatey package.
    Optional parameter that allows passing package-specific installation arguments using the --params flag.

.OUTPUTS
    [System.Boolean]
    Returns $true if the package was successfully installed or already meets requirements.
    Returns $false if the installation failed or insufficient privileges.

.EXAMPLE
    Install-ChocolateyPackage -PackageName "git"
    
    Installs the latest version of git package.

.EXAMPLE
    Install-ChocolateyPackage -PackageName "nodejs" -Version "18.17.0"
    
    Installs a specific version of nodejs package.

.EXAMPLE
    Install-ChocolateyPackage -PackageName "googlechrome" -Param "/nogoogle"
    
    Installs Google Chrome with custom installation parameters.

.EXAMPLE
    $result = Install-ChocolateyPackage -PackageName "vscode" -Version "1.75.0" -Param "/silent"
    if ($result) {
        Write-Host "Visual Studio Code installed successfully"
    } else {
        Write-Host "Failed to install Visual Studio Code"
    }
    
    Demonstrates capturing the return value and using custom parameters.

.NOTES
    - Requires administrator privileges to install packages
    - Uses Test-RunningAsAdmin to validate privileges before proceeding
    - Uses Test-ChocolateyPackageInstalled to check existing installations
    - Automatically uninstalls existing packages when version conflicts exist
    - Uses comprehensive logic to determine installation necessity:
      * Returns immediately if package with correct version exists
      * Uninstalls and reinstalls if package exists but version differs
      * Installs directly if package doesn't exist
    - Uses $LASTEXITCODE to verify command execution success
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Provides detailed debug logging for troubleshooting installation issues
    - Suppresses command output using Out-Null to avoid console clutter

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Package Management, Software Installation, Version Control
#>

Function Install-ChocolateyPackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $PackageName,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $Version,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $Param
    )
    
    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            Write-StatusMessage "Chocolatey package installation requires administrator privileges. Please run as administrator." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking administrator privileges: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        if (-not (Test-ChocolateyInstalled)) {
            Write-StatusMessage "Chocolatey is not installed. Cannot install package $PackageName." -Verbosity Warning
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking if Chocolatey is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    $testParams = @{
        PackageName = $PackageName
    }

    if($PSBoundParameters.ContainsKey('Version')) {
        $testParams.Version = $Version
    }

    try {
        $testResult = Test-ChocolateyPackageInstalled @testParams
    } catch {
        Write-StatusMessage "Error checking if package $PackageName is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if($testResult.HasFlag([InstalledState]::Pass)) {
        return $true
    }

    if($testResult.HasFlag([InstalledState]::Installed)) {
        try {
            Uninstall-ChocolateyPackage -PackageName $PackageName | Out-Null
        } catch {
            Write-StatusMessage "Error uninstalling existing package $($PackageName): $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }
    }

    $installParams = @(
        'install',
        '-y',
        $PackageName
    )
    
    if($PSBoundParameters.ContainsKey('Version')) {
        $installParams = $installParams + @('--version', $Version)
    }

    if($PSBoundParameters.ContainsKey('Param')) {
        $installParams = $installParams + @('--params', $Param)
    }

    try {
        $chocoCommand = Find-Chocolatey
        if (-not $chocoCommand) {
            Write-StatusMessage "Could not find Chocolatey command. Cannot install package $PackageName." -Verbosity Warning
            return $false
        }
    } catch {
        Write-StatusMessage "Error locating Chocolatey command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        if( -not (Test-Path $chocoCommand)) {
            Write-StatusMessage "Chocolatey command path '$chocoCommand' does not exist. Cannot install package $PackageName." -Verbosity Warning
            return $false
        }
    } catch {
        Write-StatusMessage "Error verifying Chocolatey command path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if ($PSCmdlet.ShouldProcess($PackageName, "Install Chocolatey package")) {
        try {
            Invoke-Command -ScriptBlock { & $chocoCommand @installParams | Out-Null }
        } catch {
            Write-StatusMessage "Error installing package $($PackageName): $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }
    } else {
        Write-StatusMessage "Skipping installation of Chocolatey package '$PackageName'." -Verbosity Debug
        return $true
    }
    
    if ($LASTEXITCODE -eq 0) {
        try {
            if (-not (Write-ChocolateyCache)) {
                Write-StatusMessage "Failed to write Chocolatey cache." -Verbosity Error
                return $false
            }
        } catch {
            Write-StatusMessage "Error writing Chocolatey cache: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        } 
        return $true
    } else {
        Write-StatusMessage "Failed to install: $PackageName" -Verbosity Error
        return $false
    }   
}