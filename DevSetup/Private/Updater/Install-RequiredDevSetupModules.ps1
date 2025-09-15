Function Install-RequiredDevSetupModules {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $Modules
    )

    # Ensure NuGet provider is available
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        try {
            Install-PackageProvider -Name NuGet -Force -ForceBootstrap *> $null
        } catch {
            Write-StatusMessage "Failed to install NuGet PackageProvider: $_" -Verbosity Error
            return $false
        }
    }

    # Install required modules
    foreach ($Module in $Modules) {
        if (-not (Get-Module -Name $Module -ErrorAction SilentlyContinue)) {
            try {
                Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber *> $null
            } catch {
                Write-StatusMessage "Failed to install module '$Module': $_" -Verbosity Error
            }
        } else {
            Write-StatusMessage "Module '$Module' is already installed. Skipping." -Verbosity Debug
        }
    }
    return $true
}