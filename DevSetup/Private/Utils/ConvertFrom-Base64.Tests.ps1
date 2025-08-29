BeforeAll {
    . $PSScriptRoot\ConvertFrom-Base64.ps1
    Mock Write-Error { }
}

Describe "ConvertFrom-Base64" {

    Context "When EncodedString is empty" {
        It "Should write error and return false" {
            $result = ConvertFrom-Base64 -EncodedString ""
            $result | Should -Be $false
        }
    }

    Context "When EncodedString is valid and OutputFile is not provided" {
        It "Should decode and return the string" {
            $plainText = "Hello, world!"
            $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($plainText))
            $result = ConvertFrom-Base64 -EncodedString $base64
            $result | Should -Be $plainText
        }
    }

    Context "When EncodedString is valid and OutputFile is provided" {
        It "Should decode and write to file, returning true" {
            $plainText = "Test file output"
            $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($plainText))
            $testFile = "$PSScriptRoot\test_output.txt"
            if (Test-Path $testFile) { Remove-Item $testFile }
            $result = ConvertFrom-Base64 -EncodedString $base64 -OutputFile $testFile
            $result | Should -Be $true
            (Get-Content $testFile -Raw) | Should -Be $plainText
            Remove-Item $testFile
        }
    }

    Context "When EncodedString is invalid base64" {
        It "Should write error and return false" {
            $result = ConvertFrom-Base64 -EncodedString "not_base64!"
            $result | Should -Be $false
        }
    }
}