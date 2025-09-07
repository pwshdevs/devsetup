BeforeAll {
    Function Get-GitHubRepository { }
    Function Install-GitRepository { }

    Function Set-GitHubConfiguration { }

    . (Join-Path $PSScriptRoot "Initialize-DevSetupEnvs.ps1")
    . (Join-Path $PSScriptRoot "Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "Optimize-DevSetupEnvs.ps1")
    . (Join-Path $PSScriptRoot "Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "Get-DevSetupLocalEnvPath.ps1")
    . (Join-Path $PSScriptRoot "Get-DevSetupCommunityEnvPath.ps1")
    . (Join-Path $PSScriptRoot "Get-DevSetupManifest.ps1")
    Mock Get-DevSetupEnvPath { "TestDrive:\DevSetupEnvs" }
    Mock Get-DevSetupManifest { 
        @{
            PrivateData = @{
                PSData = @{
                    EnvironmentsProjectUri = "https://github.com/example/envrepo"
                }
            }
        }
    }
    Mock Get-GitHubRepository { @{ clone_url = "https://github.com/example/envrepo.git" } }
    Mock Set-GitHubConfiguration { $true }
    Mock Test-Path { $false }
    Mock Install-GitRepository { $true }
    Mock Write-StatusMessage { }
    Mock Optimize-DevSetupEnvs { }
    Mock Write-Error { }
    Mock Write-Verbose { }
    Mock Get-DevSetupLocalEnvPath { "TestDrive:\DevSetupEnvs\environments\local" }
    Mock Get-DevSetupCommunityEnvPath { "TestDrive:\DevSetupEnvs\environments\community" }
}

Describe "Initialize-DevSetupEnvs" {

    Context "When manifest cannot be retrieved" {
        It "Should write error and return null" {
            Mock Get-DevSetupManifest { $null }
            $result = Initialize-DevSetupEnvs
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to retrieve DevSetup module manifest" }
        }
    }

    Context "When EnvironmentsProjectUri is missing" {
        It "Should write error and return null" {
            Mock Get-DevSetupManifest { @{ PrivateData = @{ PSData = @{ } } } }
            $result = Initialize-DevSetupEnvs
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "EnvironmentsProjectUri not found" }
        }
    }

    Context "When EnvironmentsProjectUri is not a .git URL and GitHub API fails" {
        It "Should write error and return null" {
            Mock Get-GitHubRepository { return $null }
            $result = Initialize-DevSetupEnvs
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to retrieve repository information or clone_url" }
        }
    }

    Context "When Get-GitHubRepository throws" {
        It "Should write error and return null" {
            Mock Get-GitHubRepository { throw "API error" }
            $result = Initialize-DevSetupEnvs
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to get repository information from GitHub" }
        }
    }

    Context "When EnvironmentsProjectUri is a .git URL" {
        It "Should use the URI directly and clone the repository" {
            Mock Get-DevSetupManifest { 
                @{
                    PrivateData = @{
                        PSData = @{
                            EnvironmentsProjectUri = "https://github.com/example/envrepo.git"
                        }
                    }
                }
            }
            $result = Initialize-DevSetupEnvs
            $result | Should -BeOfType [hashtable]
            $result.local | Should -Be "TestDrive:\DevSetupEnvs\environments\local"
            $result.community | Should -Be "TestDrive:\DevSetupEnvs\environments\community"
            Assert-MockCalled Test-Path -Scope It -Exactly 3
            Assert-MockCalled Get-GithubRepository -Scope It -Exactly 0
            Assert-MockCalled Write-Verbose -Scope It -Exactly 0 -ParameterFilter { $Message -match "Environments repository already exists*" }
            Assert-MockCalled Write-StatusMessage -Scope It -Exactly 2
            #Assert-MockCalled Install-GitRepository -Scope It -ParameterFilter { $RepositoryUrl -eq "https://github.com/example/envrepo.git" }
        }
    }

    Context "When repository path already exists" {
        It "Should not clone and should write verbose" {
            Mock Test-Path { $true }
            $result = Initialize-DevSetupEnvs
            $result | Should -BeOfType [hashtable]
            $result.local | Should -Be "TestDrive:\DevSetupEnvs\environments\local"
            $result.community | Should -Be "TestDrive:\DevSetupEnvs\environments\community"
            Assert-MockCalled Install-GitRepository -Times 0 -Scope It
            Assert-MockCalled Write-Verbose -Scope It -ParameterFilter { $Message -match "already exists" }
        }
    }

    Context "When Install-GitRepository fails" {
        It "Should write failed status message" {
            Mock Test-Path { $false }
            Mock Install-GitRepository { $null }
            $global:LASTEXITCODE = 1
            Initialize-DevSetupEnvs
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -eq "[Failed]" }
        }
    }

    Context "When Install-GitRepository succeeds" {
        It "Should write OK status message" {
            Mock Test-Path { $false }
            Mock Install-GitRepository { $null }
            $global:LASTEXITCODE = 0
            Initialize-DevSetupEnvs
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -eq "[OK]" }
        }
    }

    Context "When Optimize-DevSetupEnvs is called" {
        It "Should call Optimize-DevSetupEnvs after cloning" {
            Initialize-DevSetupEnvs
            Assert-MockCalled Optimize-DevSetupEnvs -Scope It
        }
    }

    Context "When an unexpected error occurs" {
        It "Should write error and return null" {
            Mock Get-DevSetupEnvPath { throw "Unexpected error" }
            $result = Initialize-DevSetupEnvs
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to initialize DevSetup environment" }
        }
    }
}