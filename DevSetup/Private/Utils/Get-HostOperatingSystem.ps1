Function Get-HostOperatingSystem {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    [OutputType([string])]
    Param()
    $platform = Invoke-Command -Script { [System.Environment]::OSVersion.Platform.ToString() }
    $DecodedPlatform = switch ($platform) {
            "Win32NT" { 
                "Windows" 
            }

            "Unix" { 
                $uname = ""
                try {
                    $uname = Invoke-Command -Script { & uname -s } 2>$null
                } catch {
                }
                if ($uname -eq "Darwin") {
                    "macOS"
                } else {
                    "Linux"
                }
            }

            default {
                $platform
            }
        }    
    return $DecodedPlatform
}