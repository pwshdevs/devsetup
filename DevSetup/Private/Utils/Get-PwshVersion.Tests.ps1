BeforeAll {
    . $PSScriptRoot\Get-PwshVersion.ps1
}

Describe "Get-PwshVersion" {

    Context "When called in a typical PowerShell environment" {
        It "Should return a hashtable with Major, Minor, and Patch keys" {
            $result = Get-PwshVersion
            $result | Should -BeOfType 'hashtable'
            $result.Keys | Should -Contain 'Major'
            $result.Keys | Should -Contain 'Minor'
            $result.Keys | Should -Contain 'Patch'
        }

        It "Should return correct version numbers from \$PSVersionTable" {
            $expectedMajor = $PSVersionTable.PSVersion.Major
            $expectedMinor = $PSVersionTable.PSVersion.Minor
            $expectedPatch = $PSVersionTable.PSVersion.Build
            $result = Get-PwshVersion
            $result.Major | Should -Be $expectedMajor
            $result.Minor | Should -Be $expectedMinor
            $result.Patch | Should -Be $expectedPatch
        }
    }
}