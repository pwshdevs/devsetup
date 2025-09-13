Function Invoke-VsConfigExport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$VsInstallPath
    )

    if (-not (Test-Path -Path $VsInstallPath)) {
        Write-StatusMessage "Visual Studio installation path not found: $VsInstallPath" -Verbosity Error
        return $null
    }

    try {
        $UserProfilePath = (Get-EnvironmentVariable USERPROFILE)
        if (-not (Test-Path -Path $UserProfilePath)) {
            Write-StatusMessage "User profile path not found: $UserProfilePath" -Verbosity Error
            return $null
        }
    } catch {
        Write-StatusMessage "Failed to get user profile path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        # Ensure no leftover temp config file exists
        $tempConfigFile = Join-Path $UserProfilePath "vsconfig.devsetup"
        if (Test-Path $tempConfigFile) { 
            Remove-Item $tempConfigFile -Force 
        }
    } catch {
        Write-StatusMessage "Failed to remove existing temporary config file: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }
    
    try {
        $Command = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe"
        if (-not (Test-Path -Path $Command)) {
            Write-StatusMessage "Visual Studio setup command not found: $Command" -Verbosity Error
            return $null
        }
    } catch {
        Write-StatusMessage "Failed to verify Visual Studio setup command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $exportStatus = Invoke-Command -ScriptBlock { & $Command export --installPath $VsInstallPath --config "$tempConfigFile" --passive }
        Write-StatusMessage "Result: $exportStatus" -Verbosity Debug
        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Visual Studio configuration export failed with exit code $LASTEXITCODE." -Verbosity Error
            return $null
        }
    } catch {
        Write-StatusMessage "Failed to run Visual Studio setup command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    $tempConfigFileStatus = (Wait-ForVisualStudioConfigFile -ConfigFilePath $tempConfigFile -TimeoutSeconds 60)

    if (-not $tempConfigFileStatus) {
        Write-StatusMessage "Timed out waiting for Visual Studio configuration export to complete." -Verbosity Error
        return $null
    }

    if (-not (Test-Path -Path $tempConfigFile)) {
        Write-StatusMessage "Failed to export Visual Studio configuration to temporary file." -Verbosity Error
        return $null
    }

    try {
        # Read the exported configuration
        $Config = Get-Content -Path $tempConfigFile -Raw
    } catch {
        Write-StatusMessage "Failed to read exported configuration file: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    if([string]::IsNullOrWhiteSpace($Config)) {
        Write-StatusMessage "Exported Visual Studio configuration file is empty." -Verbosity Error
        return $null
    }

    # Clean up temporary files
    try {
        if (Test-Path $tempConfigFile) { 
            Remove-Item $tempConfigFile -Force 
        }
    } catch {
        Write-StatusMessage "Failed to remove temporary config file: $_" -Verbosity Warning
    }

    return $Config
}