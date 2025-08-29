BeforeAll {
    . $PSScriptRoot\ConvertTo-Base64.ps1
    Mock Write-Error { }
}

Describe "ConvertTo-Base64" {

    Context "When converting a string to Base64" {
        It "Should return the correct Base64 string" {
            $inputString = "Hello, world!"
            $stringBytes = [System.Text.Encoding]::UTF8.GetBytes($inputString)
            $expected = [System.Convert]::ToBase64String($stringBytes)
            $result = ConvertTo-Base64 -InputString $inputString
            $result | Should -Be $expected
        }
    }

    Context "When converting a file to Base64" {
        It "Should return the correct Base64 string" {
            $inputString = "File content"
            $testFile = "${TestDrive}\test_input.txt"
            Set-Content -Path $testFile -Value $inputString
            $stringBytes = [System.IO.File]::ReadAllBytes($testFile)
            $expected = [System.Convert]::ToBase64String($stringBytes)
            $result = ConvertTo-Base64 -FilePath $testFile
            $result | Should -Be $expected
            Remove-Item $testFile
        }
    }

    Context "When file does not exist" {
        It "Should write error and return null" {
            $result = ConvertTo-Base64 -FilePath "nonexistent.txt"
            $result | Should -Be $null
        }
    }

    Context "When an exception occurs" {
        It "Should write error and return null" {
            Mock Test-Path { throw "Unexpected error" }
            $result = ConvertTo-Base64 -FilePath "anyfile.txt"
            $result | Should -Be $null
        }
    }
}