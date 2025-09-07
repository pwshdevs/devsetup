BeforeAll {
    . $PSScriptRoot\Export-DevSetupEnv.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupLocalEnvPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupCommunityEnvPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Write-NewConfig.ps1
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Mock Get-DevSetupEnvPath { "$TestDrive\DevSetup\DevSetupEnvs" }
        Mock Get-DevSetupLocalEnvPath { "$TestDrive\DevSetup\DevSetupEnvs\local" }
        Mock Get-DevSetupCommunityEnvPath { "$TestDrive\DevSetup\DevSetupEnvs\community" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) {
            Mock Get-DevSetupEnvPath { "$TestDrive\DevSetup\DevSetupEnvs" }
            Mock Get-DevSetupLocalEnvPath { "$TestDrive\DevSetup\DevSetupEnvs\local" }
            Mock Get-DevSetupCommunityEnvPath { "$TestDrive\DevSetup\DevSetupEnvs\community" }
        }
        if ($IsLinux) {
            Mock Get-DevSetupEnvPath { "$TestDrive/home/testuser/DevSetup/DevSetupEnvs" }
            Mock Get-DevSetupLocalEnvPath { "$TestDrive/home/testuser/DevSetup/DevSetupEnvs/local" }
            Mock Get-DevSetupCommunityEnvPath { "$TestDrive/home/testuser/DevSetup/DevSetupEnvs/community" }
        }
        if ($IsMacOS) {
            Mock Get-DevSetupEnvPath { "$TestDrive/Users/TestUser/DevSetup/DevSetupEnvs" }
            Mock Get-DevSetupLocalEnvPath { "$TestDrive/Users/TestUser/DevSetup/DevSetupEnvs/local" }
            Mock Get-DevSetupCommunityEnvPath { "$TestDrive/Users/TestUser/DevSetup/DevSetupEnvs/community" }
        }
    }
    Mock Write-NewConfig { param($OutFile) $OutFile }
    Mock Write-Host { }
    Mock Write-Error { }
}

Describe "Export-DevSetupEnv" {

    Context "When called with a valid name" {
        It "Should create the config file and return its path" {
            $result = Export-DevSetupEnv -Name "MyEnv"
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $expectedPath = "$TestDrive\DevSetup\DevSetupEnvs\local\MyEnv.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $expectedPath = "$TestDrive/home/testuser/DevSetup/DevSetupEnvs/local/MyEnv.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $expectedPath = "$TestDrive/Users/TestUser/DevSetup/DevSetupEnvs/local/MyEnv.devsetup"
            }
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "exported to" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When called with a valid path" {
        It "Should create the config file and return its path" {
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $result = Export-DevSetupEnv -Path "$TestDrive\MyCustomPath\MyEnv.devsetup"
                $expectedPath = "$TestDrive\MyCustomPath\MyEnv.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $result = Export-DevSetupEnv -Path "$TestDrive/MyCustomPath/MyEnv.devsetup"
                $expectedPath = "$TestDrive/MyCustomPath/MyEnv.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $result = Export-DevSetupEnv -Path "$TestDrive/MyCustomPath/MyEnv.devsetup"
                $expectedPath = "$TestDrive/MyCustomPath/MyEnv.devsetup"
            }
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "exported to" -and $ForegroundColor -eq "Green" }
        }
    }    

    Context "When called with a name that needs sanitization" {
        It "Should sanitize the name and warn" {
            $result = Export-DevSetupEnv -Name "Data Science Environment!"
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $expectedPath = "$TestDrive\DevSetup\DevSetupEnvs\local\DataScienceEnvironment.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $expectedPath = "$TestDrive/home/testuser/DevSetup/DevSetupEnvs/local/DataScienceEnvironment.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $expectedPath = "$TestDrive/Users/TestUser/DevSetup/DevSetupEnvs/local/DataScienceEnvironment.devsetup"
            }
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "sanitized" -and $ForegroundColor -eq "Yellow" }
        }
    }

    Context "When called with a path that needs sanitization" {
        It "Should sanitize the path and warn" {
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $result = Export-DevSetupEnv -Path "$TestDrive\MyCustomPath\MyEnv!.devsetup"
                $expectedPath = "$TestDrive\MyCustomPath\MyEnv.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $result = Export-DevSetupEnv -Path "$TestDrive/MyCustomPath/MyEnv!.devsetup"
                $expectedPath = "$TestDrive/MyCustomPath/MyEnv.devsetup"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $result = Export-DevSetupEnv -Path "$TestDrive/MyCustomPath/MyEnv!.devsetup"
                $expectedPath = "$TestDrive/MyCustomPath/MyEnv.devsetup"
            }
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "sanitized" -and $ForegroundColor -eq "Yellow" }
        }
    }    

    Context "When Write-NewConfig fails" {
        It "Should write error and return null" {
            Mock Write-NewConfig { param($OutFile) $null }
            $result = Export-DevSetupEnv -Name "FailEnv"
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to create configuration file" }
        }
    }
}
