BeforeAll {
    . $PSScriptRoot\Test-OperatingSystem.ps1
    . $PSScriptRoot\Get-PwshVersion.ps1
}

Describe "Test-OperatingSystem" {
    Context "When no parameters are provided" {
        It "Should return false" {
            $result = Test-OperatingSystem
            $result | Should -Be $false
        }
    }
    
    Context "When Powershell version is less than 6" {
        BeforeAll { Mock Get-PwshVersion { [PSCustomObject]@{ Major = 5 } } }

        Context "When called with -Windows" {
            It "Should return true" {
                $result = Test-OperatingSystem -Windows
                $result | Should -Be $true
            }
        }

        Context "When called with -Linux" {
            It "Should return false" {
                $result = Test-OperatingSystem -Linux
                $result | Should -Be $false
            }
        }

        Context "When called with -MacOS" {
            It "Should return false" {
                $result = Test-OperatingSystem -MacOS
                $result | Should -Be $false
            }
        }

        Context "When called with no parameters" {
            It "Should return false" {
                $result = Test-OperatingSystem
                $result | Should -Be $false
            }
        }
    }

    Context "When Powershell version is 6 or greater on windows" {
        BeforeAll { 
            Mock Get-PwshVersion { [PSCustomObject]@{ Major = 6 } }
            if($PSVersionTable.PSVersion.Major -lt 6) {
                $script:IsWindows = $true
                $script:IsLinux = $false
                $script:IsMacOS = $false
            }
        }
        It "Should return value of `$IsWindows" {
            $result = Test-OperatingSystem -Windows
            if ($IsWindows) {
                $result | Should -Be $true
            } else {
                $result | Should -Be $false
            }
        }
    }

    Context "When Powershell version is 6 or greater on linux" {
        BeforeAll { 
            Mock Get-PwshVersion { [PSCustomObject]@{ Major = 6 } }
            if($PSVersionTable.PSVersion.Major -lt 6) {
                $script:IsWindows = $false
                $script:IsLinux = $true
                $script:IsMacOS = $false
            }
        }
        It "Should return value of `$IsLinux" {
            $result = Test-OperatingSystem -Linux
            if($IsLinux) {
                $result | Should -Be $true
            } else {
                $result | Should -Be $false
            }
        }
    } 
    
    Context "When Powershell version is 6 or greater on macos" {
        BeforeAll { 
            Mock Get-PwshVersion { [PSCustomObject]@{ Major = 6 } }
            if($PSVersionTable.PSVersion.Major -lt 6) {
                $script:IsWindows = $false
                $script:IsLinux = $false
                $script:IsMacOS = $true
            }
        }
        It "Should return value of `$IsMacOS" {
            $result = Test-OperatingSystem -MacOS
            if($IsMacOS) {
                $result | Should -Be $true
            } else {
                $result | Should -Be $false
            }
        }
    }
}