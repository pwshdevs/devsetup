BeforeAll {
    . (Join-Path $PSScriptRoot Get-HomebrewCacheFile.ps1)
    . (Join-Path $PSScriptRoot ..\..\..\..\DevSetup\Private\Utils\Get-DevSetupCachePath.ps1)
    . (Join-Path $PSScriptRoot ..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1)
    if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
        Mock Get-DevSetupCachePath { return "$TestDrive\Users\TestUser\devsetup\.cache" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
        Mock Get-DevSetupCachePath { return "$TestDrive/home/testuser/devsetup/.cache" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
        Mock Get-DevSetupCachePath { return "$TestDrive/Users/testuser/devsetup/.cache" }
    }
    Mock Write-StatusMessage { }
}

Describe "Get-HomebrewCacheFile" {
    Context "Windows" {
        It "should return the correct cache file path on Windows" {
            $result = Get-HomebrewCacheFile
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $result | Should -Be "$TestDrive\Users\TestUser\devsetup\.cache\homebrew.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $result | Should -Be "$TestDrive/home/testuser/devsetup/.cache/homebrew.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $result | Should -Be "$TestDrive/Users/testuser/devsetup/.cache/homebrew.cache"
            }

            Assert-MockCalled Get-DevSetupCachePath -Exactly 1 -Scope It
        }
    }

    Context "When Get-DevSetupCachePath returns null" {
        It "should return null" {
            Mock Get-DevSetupCachePath { return $null }

            $result = Get-HomebrewCacheFile
            $result | Should -Be $null
            Assert-MockCalled Get-DevSetupCachePath -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }
}