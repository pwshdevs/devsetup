BeforeAll {
    . $PSScriptRoot\Get-ScoopVersion.ps1
    . $PSScriptRoot\Find-Scoop.ps1
}

Describe "Get-ScoopVersion" {
    Context "When scoop is not found" {
        BeforeEach {
            Mock Find-Scoop { return $null }
        }
        It "should return null" {
            $scoopVersion = Get-ScoopVersion
            $scoopVersion | Should -Be $null
        }
    }

    Context "When scoop is found but returns no version info" {
        BeforeEach {
            Mock Find-Scoop { return 'scoop' }
            Mock Invoke-Expression {
                return ''
            }
            Mock Get-Content {
                return $null
            }
            Mock Remove-Item {
                return $null
            }
        }
        It "should return null" {
            $scoopVersion = Get-ScoopVersion
            $scoopVersion | Should -Be $null
        }
    }

    Context "When scoop is found and returns version info" {
        BeforeEach {
            Mock Find-Scoop { return 'scoop' }
            Mock Invoke-Expression {
                return "b588a06e (HEAD -> master, origin/master, origin/HEAD) chore(release): Bump to version 0.5.3 (resync) (#6436)
945371469 (HEAD -> master, origin/master, origin/HEAD) tailwindcss: Update to version 4.1.12
7ecbe6adcc (HEAD -> master, origin/master, origin/HEAD) processing4: Update to version 1306-4.4.6"
            }
            Mock Remove-Item {}
        }
        It "should return the scoop version" {
            $scoopVersion = Get-ScoopVersion
            $scoopVersion | Should -Be "0.5.3"
        }
    } 

    Context "When scoop is found and returns git hash info" {
        BeforeEach {
            Mock Find-Scoop { return 'scoop' }
            Mock Invoke-Expression {
                return "b588a06e (HEAD -> master, origin/master, origin/HEAD) chore(release):
945371469 (HEAD -> master, origin/master, origin/HEAD) tailwindcss:
7ecbe6adcc (HEAD -> master, origin/master, origin/HEAD) processing4:"
            }
            Mock Remove-Item {}
        }
        It "should return the scoop git hash" {
            $scoopVersion = Get-ScoopVersion
            $scoopVersion | Should -Be "b588a06e"
        }
    }  
    
    Context "When scoop is found and but the version format changed" {
        BeforeEach {
            Mock Find-Scoop { return 'scoop' }
            Mock Invoke-Expression {
                return "(HEAD -> master, origin/master, origin/HEAD) chore(release):
(HEAD -> master, origin/master, origin/HEAD) tailwindcss:
(HEAD -> master, origin/master, origin/HEAD) processing4:"
            }
            Mock Remove-Item {}
        }
        It "should return installed" {
            $scoopVersion = Get-ScoopVersion
            $scoopVersion | Should -Be "installed"
        }
    } 
    
    Context "When scoop is found and but the version format changed to not using git release rendering" {
        BeforeEach {
            Mock Find-Scoop { return 'scoop' }
            Mock Invoke-Expression {
                return "Current Scoop version:
v0.5.3 - Released at 2025-08-11"
            }
            Mock Remove-Item {}
        }
        It "should return the scoop version" {
            $scoopVersion = Get-ScoopVersion
            $scoopVersion | Should -Be "0.5.3"
        }
    }     
    
    Context "When scoop is found and but an error is thrown" {
        BeforeEach {
            Mock Find-Scoop { return 'scoop' }
            Mock Invoke-Expression {
                throw "This is a sample error"
            }
            Mock Remove-Item {}
        }
        It "should return installed" {
            $scoopVersion = Get-ScoopVersion -WarningAction SilentlyContinue
            $scoopVersion | Should -Be "installed"
        }
    }     
}