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
    [CmdletBinding()]
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
            throw "Chocolatey package installation requires administrator privileges. Please run as administrator."
        }
        
        $testParams = @{
            PackageName = $PackageName
        }

        if($PSBoundParameters.ContainsKey('Version')) {
            $testParams.Version = $Version
        }

        $testResult = Test-ChocolateyPackageInstalled @testParams

        if($testResult.HasFlag([InstalledState]::Pass)) {
            return $true
        }

        if($testResult.HasFlag([InstalledState]::Installed)) {
            Uninstall-ChocolateyPackage -PackageName $PackageName | Out-Null
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

        $chocoCommand = Get-Command choco -ErrorAction SilentlyContinue

        $command = {
            & $chocoCommand @installParams
        }

        Invoke-Command -ScriptBlock $command | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Debug "INSTALL:Successfully installed: $PackageName"
            if (-not (Write-ChocolateyCache)) {
                Write-Warning "Failed to write Chocolatey cache."
                return $false
            }
            return $true
        } else {
            Write-Error "Failed to install: $PackageName"
            return $false
        }
    }
    catch {
        Write-Error "Error checking/installing package $PackageName`: $_"
        return $false
    }    
}