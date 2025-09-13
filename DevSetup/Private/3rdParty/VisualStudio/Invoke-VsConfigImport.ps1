Function Invoke-VsConfigImport {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Config,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$VsInstallPath
    )

    try {  
        $UserProfilePath = (Get-EnvironmentVariable USERPROFILE)
        if (-not (Test-Path -Path $UserProfilePath)) {
            Write-StatusMessage "User profile path not found: $UserProfilePath" -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Failed to get user profile path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
        
    try {
        $configFile = Join-Path -Path $UserProfilePath -ChildPath ".vssconfig-devsetup"
        if (Test-Path $configFile) { 
            Remove-Item $configFile -Force 
        }
    } catch {
        Write-StatusMessage "Failed to create config file path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        # Write the decoded configuration to the config file
        Set-Content -Path $configFile -Value $Config -Encoding UTF8 -Force
    } catch {
        Write-StatusMessage "Failed to write configuration to file: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    Write-StatusMessage "Visual Studio configuration saved to: $configFile" -ForegroundColor Green

    if (-not (Test-Path -Path $VsInstallPath)) {
        Write-StatusMessage "Visual Studio installation path not found: $VsInstallPath" -Verbosity Error
        return $false
    }

    if (-not (Test-Path -Path $configFile)) {
        Write-StatusMessage "Configuration file not found: $configFile" -Verbosity Error
        return $false
    }

    $SetupCommand = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe"
    if (-not (Test-Path -Path $SetupCommand)) {
        Write-StatusMessage "Visual Studio setup command not found: $SetupCommand" -Verbosity Error
        return $false
    }

    try {
        # Run the Visual Studio installer with the config file (suppress output)
        Write-StatusMessage "Running Visual Studio installer..." -Verbosity Debug
        $result = Invoke-Command -ScriptBlock { & $SetupCommand modify --installPath $VsInstallPath --config "$configFile" --passive --allowUnsignedExtensions }
        Write-StatusMessage "Result: $result" -Verbosity Debug
        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Visual Studio configuration import failed with exit code $LASTEXITCODE." -Verbosity Error
            return $false
        }
        return $true
    } catch {
        Write-StatusMessage "Failed to process Visual Studio configuration: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}