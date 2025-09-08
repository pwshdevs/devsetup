Function Get-HostOperatingSystem {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    [OutputType([string])]
    Param()
    $platform = [System.Environment]::OSVersion.Platform.ToString()
    $DecodedPlatform = switch ($platform) {
            "Win32NT" { 
                "Windows" 
            }

            "Unix" { 
                $uname = ""
                try {
                    $uname = (& uname -s 2>$null)
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