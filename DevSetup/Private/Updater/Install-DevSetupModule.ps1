Function Install-DevSetupModule {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $ModulePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject] $Manifest
    )

    # Determine installation path
    if(-not $Manifest.ModuleVersion -or [string]::IsNullOrEmpty($Manifest.ModuleVersion) -or -not ($Manifest.ModuleVersion -is [string])) {
        Write-StatusMessage "Invalid or missing version in manifest." -Verbosity Error
        return $false
    }

    if(-not (Test-Path -Path $ModulePath)) {
        Write-StatusMessage "Invalid ModulePath: '$ModulePath'" -Verbosity Error
        return $false
    }

    try {
        $installPath = (Join-Path (Get-DevSetupModuleInstallPath) -ChildPath $Manifest.ModuleVersion)
        if ($null -eq $installPath) {
            Write-StatusMessage "Failed to determine DevSetup module installation path." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error determining installation path: $_" -Verbosity Error
        return $false
    }

    if ($PSCmdlet.ShouldProcess("DevSetup Module", "Install to '$installPath'")) {
        # Create installation directory if it doesn't exist
        if (-not (Test-Path -Path $installPath)) {
            try {
                New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            } catch {
                Write-StatusMessage "Failed to create installation directory '$installPath': $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                return $false
            }
        }

        # Copy module files to installation path
        try {
            Copy-Item -Path (Join-Path -Path $ModulePath -ChildPath '*') -Destination $installPath -Recurse -Force | Out-Null
        } catch {
            Write-StatusMessage "Failed to copy module files to '$installPath': $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }

        Write-StatusMessage "Successfully installed DevSetup module to '$installPath'." -Verbosity Debug
        return $true
    } else {
        Write-StatusMessage "Installation of DevSetup module to '$installPath' was skipped by user." -Verbosity Warning
        return $true
    }
}