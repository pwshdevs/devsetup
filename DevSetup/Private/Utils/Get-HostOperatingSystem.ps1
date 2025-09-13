Function Get-HostOperatingSystem {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    [OutputType([string])]
    Param()
    try {
        # Use Invoke-Command to allow mocking in tests
        $platform = Invoke-Command -Script { [System.Environment]::OSVersion.Platform.ToString() }
    } catch {
        Write-StatusMessage "Failed to determine operating system platform: $_" -Verbosity Error
        return "Windows"  # Default to Windows if detection fails
    }
    $DecodedPlatform = switch ($platform) {
            "Win32NT" { 
                "Windows" 
            }

            "Unix" { 
                $uname = $null
                try {
                    $uname = Invoke-Command -Script { & uname -s } 2>$null
                } catch {
                    Write-StatusMessage "Failed to determine operating system platform using uname: $_" -Verbosity Error
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