Function Find-Chocolatey {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
    )

    # Check if Chocolatey is installed
    try {
        $Path = (Get-Command "choco" -ErrorAction SilentlyContinue).Path
    } catch {
        Write-StatusMessage "Error finding Chocolatey command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
    }

    if ($Path) {
        Write-StatusMessage "Found Chocolatey at: $Path" -Verbosity Debug
        return $Path
    } else {
        try {
            $ChocolateyInstallEnvPath = Get-EnvironmentVariable ChocolateyInstall
        } catch {
            Write-StatusMessage "Error retrieving ChocolateyInstall environment variable: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $null
        }
        if (-not $ChocolateyInstallEnvPath) {
            Write-StatusMessage "ChocolateyInstall environment variable is not set." -Verbosity Debug
            return $null
        } else {
            try {
                $Path = Join-Path $ChocolateyInstallEnvPath "bin\choco.exe"
            } catch {
                Write-StatusMessage "Error constructing Chocolatey path: $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                return $null
            }
            if (Test-Path $Path) {
                Write-StatusMessage "Found Chocolatey at: $Path" -Verbosity Debug
                return $Path
            } else {
                Write-StatusMessage "Chocolatey executable not found at expected path: $Path" -Verbosity Debug
                return $null
            }
        }
    }
}