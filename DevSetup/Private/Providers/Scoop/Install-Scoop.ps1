<#
.SYNOPSIS
    Installs the Scoop package manager on the system.

.DESCRIPTION
    This function installs Scoop package manager by downloading and executing the official installation script
    from get.scoop.sh. It automatically configures PowerShell execution policy settings and validates the
    installation success. The function performs pre-installation checks to avoid duplicate installations
    and uses Get-ScoopVersion to verify successful installation completion.

.OUTPUTS
    [System.Boolean]
    Returns $true if Scoop was successfully installed or was already installed.
    Returns $false if the installation verification fails.

.EXAMPLE
    Install-Scoop
    
    Installs Scoop package manager on the current system.

.EXAMPLE
    if (-not (Test-ScoopInstalled)) {
        Install-Scoop
        Write-Host "Scoop is now available for package management"
    }
    
    Shows conditional installation only when Scoop is not already present.

.NOTES
    **Installation Process:**
    - Checks if Scoop is already installed using Test-ScoopInstalled
    - Sets execution policy to RemoteSigned for script download
    - Downloads and executes installation script from get.scoop.sh with -RunAs parameter
    - Sets execution policy to Bypass after installation
    - Verifies installation using Get-ScoopVersion

    **Requirements:**
    - Internet connection to download the installation script
    - PowerShell execution policy modification permissions

    **Installation Method:**
    - Uses `Invoke-RestMethod get.scoop.sh` to download the installation script
    - Executes with `-RunAs` parameter for non-elevated user installation from elevated PowerShell
    - Automatically handles execution policy configuration (RemoteSigned → Bypass)

    **Verification:**
    - Uses Get-ScoopVersion to confirm successful installation
    - Returns boolean based on version retrieval success
    - Performs same verification check whether installing or if already installed

    **Error Handling:**
    - Throws exception if installation script execution fails
    - Uses SilentlyContinue for execution policy to avoid errors
    - Suppresses installation output using Out-Null for clean console experience

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Package Manager Installation, System Setup
#>
Function Install-Scoop {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    Write-StatusMessage "- Installing Scoop package manager" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
    if(-not (Test-ScoopInstalled)) {
        try {
            Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)} -RunAs" | Out-Null
        } catch {
            throw "Failed to install scoop: $_"
        }
    }
    
    $scoopVersion = Get-ScoopVersion
    if(-not ([string]::IsNullOrEmpty($scoopVersion))) {
        Write-StatusMessage "[OK]" -ForegroundColor Green
        return $true
    } else {
        Write-StatusMessage "[FAILED]" -ForegroundColor Red
        return $false
    }
}