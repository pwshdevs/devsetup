BeforeAll {
    . $PSScriptRoot\ConvertFrom-3rdPartyInstall.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\3rdParty\VisualStudio\ConvertFrom-VisualStudioInstall.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\3rdParty\VisualStudioCode\ConvertFrom-VisualStudioCodeInstall.ps1
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock ConvertFrom-VisualStudioInstall { $true }
    Mock ConvertFrom-VisualStudioCodeInstall { $true }
}

Describe "ConvertFrom-3rdPartyInstall" {

    Context "When both conversions succeed" {
        It "Should not write any warnings" {
            $result = ConvertFrom-3rdPartyInstall -Config "test"
            Assert-MockCalled Write-Warning -Exactly 0 -Scope It
            Assert-MockCalled Write-Host -Exactly 2 -Scope It
        }
    }

    Context "When Visual Studio conversion fails" {
        It "Should write a warning for Visual Studio" {
            Mock ConvertFrom-VisualStudioInstall { $false }
            Mock ConvertFrom-VisualStudioCodeInstall { $true }
            $result = ConvertFrom-3rdPartyInstall -Config "test"
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio installations" }
            Assert-MockCalled Write-Host -Exactly 2 -Scope It
        }
    }

    Context "When Visual Studio Code conversion fails" {
        It "Should write a warning for Visual Studio Code" {
            Mock ConvertFrom-VisualStudioInstall { $true }
            Mock ConvertFrom-VisualStudioCodeInstall { $false }
            $result = ConvertFrom-3rdPartyInstall -Config "test"
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio Code installation" }
            Assert-MockCalled Write-Host -Exactly 2 -Scope It
        }
    }

    Context "When both conversions fail" {
        It "Should write warnings for both" {
            Mock ConvertFrom-VisualStudioInstall { $false }
            Mock ConvertFrom-VisualStudioCodeInstall { $false }
            $result = ConvertFrom-3rdPartyInstall -Config "test"
            Assert-MockCalled Write-Warning -Exactly 2 -Scope It
            Assert-MockCalled Write-Host -Exactly 2 -Scope It
        }
    }
}