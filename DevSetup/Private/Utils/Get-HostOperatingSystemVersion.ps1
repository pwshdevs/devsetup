Function Get-HostOperatingSystemVersion {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    [OutputType([string])]
    Param()
    $platform = Invoke-Command -Script { [System.Environment]::OSVersion.Platform.ToString() }
    $friendlyPlatform = (Get-HostOperatingSystem)
        # Get friendly OS version
    $friendlyOsVersion = switch ($platform) {
        "Win32NT" {
            try {
                $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
                if ($osInfo) {
                    $osInfo.Caption -replace "Microsoft ", ""
                } else {
                    Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
                }
            }
            catch {
                Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
            }
        }

        "Unix" {
            if ($friendlyPlatform -eq "macOS") {
                try {
                    $macVersion = Invoke-Command -Script { & sw_vers -productVersion 2>$null }
                    if ($macVersion) {
                        "macOS $macVersion"
                    } else {
                        Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
                    }
                }
                catch {
                    Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
                }
            } else {
                # Linux
                try {
                    $linuxVersion = ""
                    if (Test-Path "/etc/os-release") {
                        $osRelease = Get-Content "/etc/os-release" | Where-Object { $_ -like "PRETTY_NAME=*" }
                        if ($osRelease) {
                            $linuxVersion = ($osRelease -split '=')[1] -replace '"', ''
                        }
                    }
                    if ($linuxVersion) {
                        $linuxVersion
                    } else {
                        Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
                    }
                }
                catch {
                    Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
                }
            }
        }
        default {
            Invoke-Command -Script { [System.Environment]::OSVersion.VersionString }
        }
    }
    return $friendlyOsVersion
}