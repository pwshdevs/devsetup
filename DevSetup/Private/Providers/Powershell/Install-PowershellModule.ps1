<#
.SYNOPSIS
    Installs a PowerShell module with specified parameters and scope validation.

.DESCRIPTION
    Installs a PowerShell module using `Install-Module` with comprehensive validation and scope management.
    Checks for existing installations and handles version/scope conflicts by intelligently uninstalling and reinstalling as needed.
    Supports both `CurrentUser` and `AllUsers` scopes, with privilege validation for `AllUsers`.

.PARAMETER ModuleName
    The name of the PowerShell module to install.
    Mandatory and must be a valid, non-empty string.

.PARAMETER Version
    The specific version of the module to install.
    Optional; installs the latest version if not provided.

.PARAMETER Force
    Switch to force installation even if the module already exists.
    Optional; passes the `-Force` flag to `Install-Module`.

.PARAMETER AllowClobber
    Switch to allow installation of modules that contain cmdlets with the same names as existing cmdlets.
    Optional; passes the `-AllowClobber` flag to `Install-Module`.

.PARAMETER Scope
    The installation scope for the module.
    Optional; valid values are `'CurrentUser'` or `'AllUsers'`. Defaults to `'CurrentUser'`.
    `AllUsers` scope requires administrator privileges.

.OUTPUTS
    `[System.Boolean]`
    Returns `$true` if the module was successfully installed or already meets requirements.
    Returns `$false` if the installation failed.

.EXAMPLE
    Install-PowershellModule -ModuleName "posh-git"
    # Installs the latest version of posh-git module for the current user.

.EXAMPLE
    Install-PowershellModule -ModuleName "PSReadLine" -Version "2.2.6"
    # Installs a specific version of PSReadLine module for the current user.

.EXAMPLE
    Install-PowershellModule -ModuleName "PowerShellGet" -Scope "AllUsers" -Force
    # Installs PowerShellGet module for all users with force flag (requires administrator privileges).

.EXAMPLE
    Install-PowershellModule -ModuleName "Az" -AllowClobber -Scope "CurrentUser"
    # Installs the Az module allowing cmdlet name conflicts for the current user.

.NOTES
    **Scope Requirements:**
    - Administrator privileges required for `AllUsers` scope.
    - Uses `Test-PowershellModuleInstalled` to check existing installations.

    **Installation Logic:**
    - Returns immediately if module with correct version and scope exists.
    - Uninstalls and reinstalls if version matches but scope differs.
    - Reinstalls in-place if scope matches but version differs.
    - Uninstalls and reinstalls if both version and scope differ.

    **Error Handling:**
    - Uses try/catch for robust error handling.
    - Returns `$false` on any failure.

    **Parameter Splatting:**
    - Uses parameter splatting for reliable `Install-Module` execution.

.LINK

.COMPONENT
    DevSetup.Providers.PowerShell

.FUNCTIONALITY
    Module Management, Package Installation, Scope Validation
#>

Function Install-PowershellModule {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $ModuleName,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $Version,

        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,

        [Parameter(Mandatory=$false)]
        [Switch] $AllowClobber = $false,

        [Parameter(Mandatory=$false)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [String] $Scope = 'CurrentUser'
    )
    
    try {
        # Check if running as administrator only when installing for all users
        if ($Scope -eq 'AllUsers' -and (-not (Test-RunningAsAdmin))) {
            throw "PowerShell module installation to AllUsers scope requires administrator privileges. Please run as administrator or use CurrentUser scope."
        }
        
        $installParams = @{
            Name = $ModuleName
            Force = $Force
            Scope = $Scope
            AllowClobber = $AllowClobber
            SkipPublisherCheck = $true
        }

        $testParams = @{
            ModuleName = $ModuleName
            Scope = $Scope
        }

        if($PSBoundParameters.ContainsKey('Version')) {
            $testParams.Version = $Version
            $installParams.RequiredVersion = $Version
        }

        $testResult = Test-PowershellModuleInstalled @testParams

        if($testResult.HasFlag([InstalledState]::Pass)) {
            return $true
        }

        if($testResult.HasFlag([InstalledState]::Installed)) {
            try {
                Uninstall-PowershellModule -ModuleName $ModuleName -WhatIf:$WhatIf
            } catch {
                # Uninstall might have failed, we keep going anyways
                Write-StatusMessage "Failed to uninstall existing module '$ModuleName': $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            }
        }

        # Install the PowerShell module
        if ($PSCmdlet.ShouldProcess($ModuleName, "Install-Module")) {
            Install-Module @installParams
        }
        return $true
    }
    catch {
        return $false
    }    
}