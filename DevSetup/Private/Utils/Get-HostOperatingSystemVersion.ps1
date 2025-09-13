Function Get-HostOperatingSystemVersion {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    [OutputType([string])]
    Param()

    $unfriendlyOsVersion = "Unknown"
    try {
        $unfriendlyOsVersion = Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
        if ([string]::IsNullOrEmpty($unfriendlyOsVersion)) {
            $unfriendlyOsVersion = "Unknown"
        }
    } catch {
        Write-StatusMessage "Failed to get OS version string: $_" -Verbosity Error
        return $unfriendlyOsVersion  # Default to Windows if detection fails
    }

    try {
        $friendlyPlatform = (Get-HostOperatingSystem)
    } catch {
        Write-StatusMessage "Failed to get friendly OS platform: $_" -Verbosity Error
        return $unfriendlyOsVersion
    }

    $friendlyOsVersion = switch($friendlyPlatform) {
        "Windows" { 
            try {
                $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
                if (-not ([string]::IsNullOrEmpty($osInfo))) {
                    $osInfo.Caption -replace "Microsoft ", ""
                } else {
                    $unfriendlyOsVersion
                }
            }
            catch {
                Write-StatusMessage "Failed to get Windows OS information: $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                $unfriendlyOsVersion
            }            
         }
        "macOS" { 
            try {
                $macVersion = Invoke-Command -Script { & sw_vers -productVersion 2>$null }
                if (-not ([string]::IsNullOrEmpty($macVersion))) {
                    "macOS $macVersion"
                } else {
                    $unfriendlyOsVersion
                }
            }
            catch {
                Write-StatusMessage "Failed to get macOS information: $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                $unfriendlyOsVersion
            }            
        }
        "Linux" { 
            try {
                $linuxVersion = $null
                if (Test-Path "/etc/os-release") {
                    $osRelease = Get-Content "/etc/os-release" | Where-Object { $_ -like "PRETTY_NAME=*" }
                    if ($osRelease) {
                        $linuxVersion = ($osRelease -split '=')[1] -replace '"', ''
                    }
                }
                if (-not ([string]::IsNullOrEmpty($linuxVersion))) {
                    $linuxVersion
                } else {
                    $unfriendlyOsVersion
                }
            }
            catch {
                Write-StatusMessage "Failed to get Linux OS information: $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                $unfriendlyOsVersion
            }            
         }
        default { $unfriendlyOsVersion }
    }

    return $friendlyOsVersion
}