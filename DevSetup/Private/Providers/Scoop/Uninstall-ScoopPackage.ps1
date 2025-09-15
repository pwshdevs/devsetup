<#
.SYNOPSIS
    Uninstalls a Scoop package from the system.

.DESCRIPTION
    This function removes a specified Scoop package from the system by executing the 'scoop uninstall' command.
    It includes validation to ensure Scoop is installed and available before attempting the uninstall operation.
    The function checks if the package is installed before attempting removal and provides error handling with 
    a boolean result indicating success or failure.

.PARAMETER PackageName
    The name of the Scoop package to uninstall.
    This parameter is mandatory and must be a valid string representing an installed Scoop package.

.OUTPUTS
    [System.Boolean]
    Returns $true if the package was successfully uninstalled or if the package was not installed, 
    $false if the uninstall operation failed.

.EXAMPLE
    Uninstall-ScoopPackage -PackageName "git"
    
    Uninstalls the 'git' package from Scoop.

.EXAMPLE
    Uninstall-ScoopPackage -PackageName "nodejs"
    
    Removes the 'nodejs' package from the system via Scoop.

.EXAMPLE
    $result = Uninstall-ScoopPackage -PackageName "7zip"
    if ($result) {
        Write-Host "7zip successfully removed or was not installed"
    } else {
        Write-Host "Failed to remove 7zip"
    }
    
    Demonstrates capturing the return value to check uninstall success.

.NOTES
    - Requires Scoop to be installed on the system
    - Uses Test-ScoopPackageInstalled function to verify package existence before uninstall
    - Returns $true if package is not installed (considered successful since goal is achieved)
    - Returns $false immediately if Scoop is not installed or cannot be found
    - Provides warning messages for common failure scenarios

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Package Management, Package Removal
#>
Function Uninstall-ScoopPackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,
        [switch]$Global
    )

    try {
        if(-Not (Test-ScoopInstalled)) {
            Write-StatusMessage "Scoop is not installed. Cannot check for components." -Verbosity Debug
            return $false
        }
    } catch {
        Write-StatusMessage "Could not verify Scoop installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $scoopCommand = Find-Scoop
        if (-not $scoopCommand) {
            Write-StatusMessage "Failed to find Scoop command. Cannot check for components." -Verbosity Debug
            return $false
        }
    } catch {
        Write-StatusMessage "Error finding Scoop command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $packageState = Test-ScoopComponentInstalled -Package -Name $PackageName
    } catch {
        Write-StatusMessage "Could not verify if Scoop package '$PackageName' is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
    if (-not ($packageState.HasFlag([InstalledState]::Pass))) {
        Write-StatusMessage "Package not installed, can not remove." -Verbosity Debug
        return $true
    }

    $uninstallArgs = @('uninstall', $PackageName)
    if($Global) {
        $uninstallArgs += '--global'
    }

    if ($PSCmdlet.ShouldProcess($PackageName, "Uninstall Scoop Package")) {
        try {
            Invoke-Command -ScriptBlock { & $scoopCommand @uninstallArgs} *> $null
        } catch {
            Write-StatusMessage "Failed to execute uninstall command for Scoop package '$PackageName': $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }
    }
    if ($LASTEXITCODE -eq 0) {
        Write-StatusMessage "Uninstalled Scoop package: $PackageName" -Verbosity Debug
        return $true
    } else {
        Write-StatusMessage "Failed to uninstall Scoop package: $PackageName" -Verbosity Debug
        return $false
    }
}