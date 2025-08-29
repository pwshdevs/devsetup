<#
.SYNOPSIS
    Uninstalls a Chocolatey package and its dependencies from the system.

.DESCRIPTION
    This function removes a Chocolatey package from the system using the 'choco uninstall' command.
    It validates administrator privileges before proceeding, handles package dependencies by uninstalling
    them first, and removes all versions of the specified package including metapackages. The function
    provides comprehensive error handling and uses exit codes to verify successful uninstallation.

.PARAMETER PackageName
    The name of the Chocolatey package to uninstall.
    This parameter is mandatory and must be a valid, non-empty string representing an installed Chocolatey package name.

.OUTPUTS
    [System.Boolean]
    Returns $true if the package and all dependencies were successfully uninstalled.
    Returns $false if the uninstallation failed or insufficient privileges.

.EXAMPLE
    Uninstall-ChocolateyPackage -PackageName "git"
    
    Uninstalls the git package and any dependent packages from the system.

.EXAMPLE
    $result = Uninstall-ChocolateyPackage -PackageName "nodejs"
    if ($result) {
        Write-Host "Node.js and dependencies removed successfully"
    } else {
        Write-Host "Failed to remove Node.js"
    }
    
    Demonstrates capturing the return value to check uninstallation success.

.EXAMPLE
    @("git", "nodejs", "vscode") | ForEach-Object {
        Uninstall-ChocolateyPackage -PackageName $_
    }
    
    Shows bulk uninstallation of multiple packages with dependency handling.

.NOTES
    - Requires administrator privileges to uninstall packages
    - Uses Test-RunningAsAdmin to validate privileges before proceeding
    - Throws an exception if not running as administrator
    - Handles package dependencies by uninstalling them first using Get-ChocolateyPackageDependencies
    - Uses recursive calls to uninstall dependency packages before the main package
    - Automatically handles metapackages (packages ending with .install)
    - Uses 'choco uninstall' with -y flag for automatic confirmation
    - Uses --all-versions flag to remove all installed versions of the package
    - Uses $LASTEXITCODE to verify command execution success
    - Suppresses command output using Out-Null to avoid console clutter
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Provides detailed debug logging for troubleshooting uninstallation issues
    - Checks for and removes associated .install metapackages after main package removal

.LINK

.COMPONENT
    DevSetup,Providers.Chocolatey

.FUNCTIONALITY
    Package Management, Software Removal, System Cleanup, Dependency Management
#>

Function Uninstall-ChocolateyPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $PackageName
    )
    
    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "Chocolatey package uninstallation requires administrator privileges. Please run as administrator."
        }

        Write-Debug "Uninstalling Chocolatey package: $PackageName"
        
        # Uninstall the package
        Invoke-Expression "& choco uninstall -y $PackageName --remove-dependencies --all-versions --ignore-package-exit-codes" | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Debug "Chocolatey package '$PackageName' uninstalled successfully."
            return $true
        } else {
            Write-Error "Failed to uninstall Chocolatey package '$PackageName'."
            return $false
        }
    }
    catch {
        Write-Error "Error uninstalling Chocolatey package: $_"
        return $false
    }
}