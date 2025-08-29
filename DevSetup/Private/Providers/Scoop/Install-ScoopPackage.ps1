<#
.SYNOPSIS
    Installs a Scoop package on the system.

.DESCRIPTION
    This function installs a specified Scoop package by executing the 'scoop install' command.
    It includes validation to ensure Scoop is installed and available before attempting the installation.
    The function supports package versioning, bucket specification, and global installation scope.
    If the package is already installed and the global scope matches, it will be uninstalled first to ensure a clean installation.
    The function verifies successful installation using Test-ScoopComponentInstalled with version and scope validation.

.PARAMETER PackageName
    The name of the Scoop package to install.
    This parameter is mandatory and must be a valid string representing a Scoop package.

.PARAMETER Version
    The specific version of the package to install.
    Optional parameter that appends version specification to the package name (e.g., "package@1.2.3").

.PARAMETER Bucket
    The bucket name where the package is located.
    Optional parameter that prepends bucket specification to the package name (e.g., "extras/package").

.PARAMETER Global
    Switch parameter to install the package globally.
    When specified, adds the --global flag to the scoop install command.

.OUTPUTS
    [System.Boolean]
    Returns $true if the package was successfully installed and verified, $false if the installation failed.

.EXAMPLE
    Install-ScoopPackage -PackageName "git"
    
    Installs the 'git' package from the main bucket.

.EXAMPLE
    Install-ScoopPackage -PackageName "nodejs" -Version "18.17.0"
    
    Installs a specific version of the 'nodejs' package.

.EXAMPLE
    Install-ScoopPackage -PackageName "7zip" -Global
    
    Installs the '7zip' package globally for all users.

.EXAMPLE
    Install-ScoopPackage -PackageName "firefox" -Bucket "extras"
    
    Installs the 'firefox' package from the 'extras' bucket.

.EXAMPLE
    Install-ScoopPackage -PackageName "python" -Version "3.11.5" -Bucket "main" -Global
    
    Installs a specific version of Python from the main bucket globally.

.NOTES
    - Requires Scoop to be installed on the system
    - Only uninstalls existing package if it's already installed AND global scope matches exactly
    - Uses Test-ScoopComponentInstalled to verify installation success with version and scope validation
    - Supports bucket/package@version syntax for package specification
    - Returns $false immediately if Scoop is not installed or cannot be found
    - Provides detailed warning and error messages for failure scenarios
    - Uses proper argument splatting for reliable command execution
    - Includes comprehensive try-catch error handling for robust failure management
    - Installation verification checks name, version (if specified), and global scope (if specified)

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Package Management, Package Installation
#>
Function Install-ScoopPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Bucket,

        [Parameter(Mandatory=$false)]
        [switch]$Global
    )

    try {
        if(-Not (Test-ScoopInstalled)) {
            return $false
        }

        $scoopCommand = Find-Scoop
        if (-not $scoopCommand) {
            return $false
        }

        $Params = @{
            Package = $true
            Name    = $PackageName
        }

        if($PSBoundParameters.ContainsKey('Version') -and $Version) {
            $Params.Version = $Version
        }

        if($Global) {
            $Params.Global = $Global
        }

        [InstalledState]$packageState = Test-ScoopComponentInstalled @Params
        if ($packageState -eq [InstalledState]::Pass) {
            Write-Debug "Scoop package '$PackageName' is already installed with the specified version and global scope."
            return $true
        } 

        if($packageState.HasFlag([InstalledState]::Installed)) {
            Write-Debug "Scoop package '$PackageName' is installed but does not meet the global scope and/or version requirements. Reinstalling..."
            Uninstall-ScoopPackage -PackageName $PackageName | Out-null
        }

        $fullPackageName = $PackageName
        if ($PSBoundParameters.ContainsKey('Bucket')) {
            $fullPackageName = "$Bucket/$PackageName"
        }
        
        # Add version if specified
        if ($PSBoundParameters.ContainsKey('Version')) {
            $fullPackageName += "@$Version"
        }
        
        # Build arguments array for installation
        $installArgs = @("install", $fullPackageName)
        
        # Add global flag if specified
        if ($Global) {
            $installArgs += "--global"
        }
        
        # Execute the install command with proper argument parsing
        $command = {
            & $scoopCommand @installArgs *> $null
        }

        Invoke-Command -ScriptBlock $command | Out-Null
        if ($LASTEXITCODE -ne 0) {
            return $false
        }

        if (-not (Write-ScoopCache)) {
            return $false
        }        
        return Test-ScoopComponentInstalled @Params
    } catch {
        return $false
    }
}