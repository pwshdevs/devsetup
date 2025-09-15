BeforeAll {
    . $PSScriptRoot\Format-CenterText.ps1
}

Describe "Format-CenterText" {

    Context "When centering text within specified width" {
        It "Should center text with equal padding on both sides for even padding" {
            $result = Format-CenterText -Text "Hello" -Width 11
            $result | Should -Be "   Hello   "
            $result.Length | Should -Be 11
        }

        It "Should center text with left padding one less than right for odd padding" {
            $result = Format-CenterText -Text "Hello" -Width 12
            $result | Should -Be "   Hello    "
            $result.Length | Should -Be 12
        }

        It "Should center single character text" {
            $result = Format-CenterText -Text "X" -Width 5
            $result | Should -Be "  X  "
            $result.Length | Should -Be 5
        }

        It "Should center text with minimum width" {
            $result = Format-CenterText -Text " " -Width 6
            $result | Should -Be "      "
            $result.Length | Should -Be 6
        }

        It "Should center text with width of 1" {
            $result = Format-CenterText -Text "A" -Width 1
            $result | Should -Be "A"
            $result.Length | Should -Be 1
        }
    }

    Context "When text width equals specified width" {
        It "Should return text unchanged when lengths are equal" {
            $text = "Hello"
            $result = Format-CenterText -Text $text -Width 5
            $result | Should -Be $text
            $result.Length | Should -Be 5
        }

        It "Should return long text unchanged when lengths are equal" {
            $text = "This is a test"
            $result = Format-CenterText -Text $text -Width 14
            $result | Should -Be $text
            $result.Length | Should -Be 14
        }
    }

    Context "When text width exceeds specified width" {
        It "Should return text unchanged when text is longer than width" {
            $text = "This text is too long"
            $result = Format-CenterText -Text $text -Width 10
            $result | Should -Be $text
            $result.Length | Should -Be 21
        }

        It "Should return text unchanged when width is 0" {
            $text = "Hello"
            $result = Format-CenterText -Text $text -Width 0
            $result | Should -Be $text
        }

        It "Should return text unchanged when width is negative" {
            $text = "Hello"
            $result = Format-CenterText -Text $text -Width -5
            $result | Should -Be $text
        }
    }

    Context "When handling special characters and unicode" {
        It "Should center text with spaces" {
            $result = Format-CenterText -Text "Hello World" -Width 21
            $result | Should -Be "     Hello World     "
            $result.Length | Should -Be 21
        }

        It "Should center text with tabs" {
            $text = "`tTab`t"
            $result = Format-CenterText -Text $text -Width 10
            $result.Length | Should -Be 10
            $result | Should -Match "Tab"
        }

        It "Should center text with newlines" {
            $text = "Line1`nLine2"
            $result = Format-CenterText -Text $text -Width 20
            $result.Length | Should -Be 20
            $result | Should -Match "Line1"
            $result | Should -Match "Line2"
        }

        It "Should handle unicode characters" {
            $result = Format-CenterText -Text "Héllo" -Width 11
            $result | Should -Be "   Héllo   "
            $result.Length | Should -Be 11
        }

        It "Should handle special symbols" {
            $result = Format-CenterText -Text "A*B" -Width 9
            $result | Should -Be "   A*B   "
            $result.Length | Should -Be 9
        }
    }

    Context "When handling different data types" {
        It "Should convert numbers to strings and center them" {
            $result = Format-CenterText -Text 123 -Width 7
            $result | Should -Be "  123  "
            $result.Length | Should -Be 7
        }

        It "Should convert boolean to strings and center them" {
            $result = Format-CenterText -Text $true -Width 8
            $result | Should -Be "  True  "
            $result.Length | Should -Be 8
        }

        It "Should handle string values that are effectively empty" {
            $result = Format-CenterText -Text " " -Width 6
            $result | Should -Be "      "
            $result.Length | Should -Be 6
        }

        It "Should handle objects by converting to string representation" {
            $obj = [PSCustomObject]@{ Name = "Test" }
            $result = Format-CenterText -Text $obj -Width 50
            $result.Length | Should -Be 50
            $result | Should -Match "Name=Test"
        }
    }

    Context "When testing edge cases and boundary conditions" {
        It "Should handle very large width values" {
            $result = Format-CenterText -Text "Hi" -Width 1000
            $result.Length | Should -Be 1000
            $result | Should -Match "^\s{499}Hi\s{499}$"
        }

        It "Should handle width of exactly text length plus 1" {
            $result = Format-CenterText -Text "Test" -Width 5
            $result | Should -Be "Test "
            $result.Length | Should -Be 5
        }

        It "Should handle width of exactly text length plus 2" {
            $result = Format-CenterText -Text "Test" -Width 6
            $result | Should -Be " Test "
            $result.Length | Should -Be 6
        }
    }

    Context "When testing mathematical calculations" {
        It "Should correctly calculate left padding for odd total padding" {
            # Text = "ABC" (3 chars), Width = 10, Padding = 7, Left = 3, Right = 4
            $result = Format-CenterText -Text "ABC" -Width 10
            $leftSpaces = ($result -split 'ABC')[0].Length
            $rightSpaces = ($result -split 'ABC')[1].Length
            $leftSpaces | Should -Be 3
            $rightSpaces | Should -Be 4
            $result | Should -Be "   ABC    "
        }

        It "Should correctly calculate left padding for even total padding" {
            # Text = "AB" (2 chars), Width = 8, Padding = 6, Left = 3, Right = 3
            $result = Format-CenterText -Text "AB" -Width 8
            $leftSpaces = ($result -split 'AB')[0].Length
            $rightSpaces = ($result -split 'AB')[1].Length
            $leftSpaces | Should -Be 3
            $rightSpaces | Should -Be 3
            $result | Should -Be "   AB   "
        }

        It "Should use Math.Floor for left padding calculation" {
            # Verify that left padding uses floor (truncates decimals)
            # Text = "X" (1 char), Width = 4, Padding = 3, Left = Floor(1.5) = 1, Right = 2
            $result = Format-CenterText -Text "X" -Width 4
            $leftSpaces = ($result -split 'X')[0].Length
            $rightSpaces = ($result -split 'X')[1].Length
            $leftSpaces | Should -Be 1
            $rightSpaces | Should -Be 2
            $result | Should -Be " X  "
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $result = Format-CenterText -Text "Windows" -Width 15
            $result | Should -Be "    Windows    "
            $result.Length | Should -Be 15
        }

        It "Should work on Linux" {
            $result = Format-CenterText -Text "Linux" -Width 13
            $result | Should -Be "    Linux    "
            $result.Length | Should -Be 13
        }

        It "Should work on macOS" {
            $result = Format-CenterText -Text "macOS" -Width 11
            $result | Should -Be "   macOS   "
            $result.Length | Should -Be 11
        }
    }

    Context "PowerShell 5.1 compatibility" {
        It "Should not use PowerShell 6+ only features" {
            # Verify no use of ?? operator or other PS6+ features
            $functionContent = Get-Content $PSScriptRoot\Format-CenterText.ps1 -Raw
            $functionContent | Should -Not -Match '\?\?'  # Null coalescing operator
            $functionContent | Should -Not -Match '\?\.'  # Null conditional operator
        }

        It "Should use compatible Math.Floor method" {
            # Test that Math.Floor works in PS 5.1
            { Format-CenterText -Text "Test" -Width 10 } | Should -Not -Throw
        }

        It "Should use compatible string operations" {
            # Test string multiplication and concatenation work in PS 5.1
            $result = Format-CenterText -Text "PS5.1" -Width 15
            $result | Should -Be "     PS5.1     "
            $result.Length | Should -Be 15
        }

        It "Should work with older .NET Framework string handling" {
            # Test that string operations work with .NET Framework 4.x
            $result = Format-CenterText -Text "Framework" -Width 17
            $result | Should -Be "    Framework    "
            $result.Length | Should -Be 17
        }
    }

    Context "Performance and stress testing" {
        It "Should handle multiple consecutive calls efficiently" {
            $results = @()
            for ($i = 1; $i -le 100; $i++) {
                $results += Format-CenterText -Text "Item$i" -Width 20
            }
            $results.Count | Should -Be 100
            $results[0] | Should -Match "Item1"
            $results[99] | Should -Match "Item100"
        }

        It "Should handle very long text efficiently" {
            $longText = "A" * 1000
            $result = Format-CenterText -Text $longText -Width 500
            $result | Should -Be $longText  # Should return unchanged since text > width
            $result.Length | Should -Be 1000
        }

        It "Should handle repeated characters" {
            $result = Format-CenterText -Text ("X" * 5) -Width 15
            $result | Should -Be "     XXXXX     "
            $result.Length | Should -Be 15
        }
    }

    Context "Parameter validation and error handling" {
        It "Should accept mandatory Text parameter" {
            { Format-CenterText -Text "Required" -Width 10 } | Should -Not -Throw
        }

        It "Should accept mandatory Width parameter" {
            { Format-CenterText -Text "Test" -Width 5 } | Should -Not -Throw
        }

        It "Should handle zero width gracefully" {
            $result = Format-CenterText -Text "Test" -Width 0
            $result | Should -Be "Test"
        }

        It "Should handle extremely large width values" {
            # Test with large but reasonable width (avoid memory issues in test environment)
            $result = Format-CenterText -Text "Big" -Width 100
            $result.Length | Should -Be 100
        }
    }
}