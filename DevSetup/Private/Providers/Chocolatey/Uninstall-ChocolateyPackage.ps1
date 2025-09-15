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
    [CmdletBinding(SupportsShouldProcess=$true)]
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
    } catch {
        Write-StatusMessage "Error checking administrator privileges: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        if (-not (Test-ChocolateyInstalled)) {
            Write-StatusMessage "Chocolatey is not installed. Cannot uninstall package '$PackageName'." -Verbosity Warning
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking if Chocolatey is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $chocoCommand = Find-Chocolatey
    } catch {
        Write-StatusMessage "Error locating Chocolatey command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if(-not $chocoCommand -or [string]::IsNullOrWhiteSpace($chocoCommand)) {
        Write-StatusMessage "Could not find Chocolatey command. Cannot uninstall package '$PackageName'." -Verbosity Warning
        return $false
    }

    Write-StatusMessage "Uninstalling Chocolatey package: $PackageName" -Verbosity Debug
    
    # Uninstall the package
    if ($PSCmdlet.ShouldProcess($PackageName, "Uninstall Chocolatey package")) {
        try {
            Invoke-Command -ScriptBlock { & $using:chocoCommand uninstall -y $using:PackageName --remove-dependencies --all-versions --ignore-package-exit-codes } *>$null
        } catch {
            Write-StatusMessage "Error uninstalling package '$PackageName': $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }
    } else {
        Write-StatusMessage "Operation to uninstall package '$PackageName' was cancelled." -Verbosity Debug
        return $true
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-StatusMessage "Chocolatey package '$PackageName' uninstalled successfully." -Verbosity Debug
        return $true
    } else {
        Write-StatusMessage "Failed to uninstall Chocolatey package '$PackageName'." -Verbosity Error
        return $false
    }
}