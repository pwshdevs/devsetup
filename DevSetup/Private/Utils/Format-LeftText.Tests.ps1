BeforeAll {
    . $PSScriptRoot\Format-LeftText.ps1
}

Describe "Format-LeftText" {

    Context "When left-aligning text within specified width" {
        It "Should left-align text with leading space and trailing spaces" {
            $result = Format-LeftText -Text "Hello" -Width 10
            $result | Should -Be " Hello    "
            $result.Length | Should -Be 10
        }

        It "Should left-align single character text" {
            $result = Format-LeftText -Text "X" -Width 5
            $result | Should -Be " X   "
            $result.Length | Should -Be 5
        }

        It "Should left-align text with minimum width" {
            $result = Format-LeftText -Text "Hi" -Width 4
            $result | Should -Be " Hi "
            $result.Length | Should -Be 4
        }

        It "Should handle width of exactly text length plus 1" {
            $result = Format-LeftText -Text "Test" -Width 5
            $result | Should -Be " Test"
            $result.Length | Should -Be 5
        }

        It "Should handle width of exactly text length plus 2" {
            $result = Format-LeftText -Text "Test" -Width 6
            $result | Should -Be " Test "
            $result.Length | Should -Be 6
        }
    }

    Context "When text width equals or exceeds specified width" {
        It "Should return text with leading space when formatted text equals width" {
            $result = Format-LeftText -Text "Test" -Width 5
            $result | Should -Be " Test"
            $result.Length | Should -Be 5
        }

        It "Should return text unchanged when formatted text exceeds width" {
            $result = Format-LeftText -Text "This is a long text" -Width 10
            $result | Should -Be " This is a long text"
            $result.Length | Should -Be 20  # Original length + 1 for leading space
        }

        It "Should return text unchanged when width is 0" {
            $result = Format-LeftText -Text "Hello" -Width 0
            $result | Should -Be " Hello"
            $result.Length | Should -Be 6
        }

        It "Should return text unchanged when width is negative" {
            $result = Format-LeftText -Text "Hello" -Width -5
            $result | Should -Be " Hello"
            $result.Length | Should -Be 6
        }

        It "Should handle very long text exceeding width" {
            $longText = "A" * 50
            $result = Format-LeftText -Text $longText -Width 20
            $result | Should -Be " $longText"
            $result.Length | Should -Be 51
        }
    }

    Context "When handling special characters and content" {
        It "Should left-align text with spaces" {
            $result = Format-LeftText -Text "Hello World" -Width 20
            $result | Should -Be " Hello World        "
            $result.Length | Should -Be 20
        }

        It "Should handle text with tabs" {
            $result = Format-LeftText -Text "Tab`tText" -Width 15
            $result | Should -Be " Tab`tText      "
            $result.Length | Should -Be 15
        }

        It "Should handle text with newlines" {
            $result = Format-LeftText -Text "Line1`nLine2" -Width 20
            $result | Should -Be " Line1`nLine2        "
            $result.Length | Should -Be 20
        }

        It "Should handle unicode characters" {
            $result = Format-LeftText -Text "Héllo" -Width 12
            $result | Should -Be " Héllo      "
            $result.Length | Should -Be 12
        }

        It "Should handle text with leading spaces" {
            $result = Format-LeftText -Text " Spaced" -Width 12
            $result | Should -Be "  Spaced    "
            $result.Length | Should -Be 12
        }

        It "Should handle text with trailing spaces" {
            $result = Format-LeftText -Text "Spaced " -Width 12
            $result | Should -Be " Spaced     "
            $result.Length | Should -Be 12
        }
    }

    Context "When handling different data types" {
        It "Should convert numbers to strings and left-align them" {
            $result = Format-LeftText -Text 123 -Width 8
            $result | Should -Be " 123    "
            $result.Length | Should -Be 8
        }

        It "Should convert boolean to strings and left-align them" {
            $result = Format-LeftText -Text $true -Width 10
            $result | Should -Be " True     "
            $result.Length | Should -Be 10
        }

        It "Should convert zero to string and left-align it" {
            $result = Format-LeftText -Text 0 -Width 6
            $result | Should -Be " 0    "
            $result.Length | Should -Be 6
        }

        It "Should convert false to string and left-align it" {
            $result = Format-LeftText -Text $false -Width 8
            $result | Should -Be " False  "
            $result.Length | Should -Be 8
        }

        It "Should handle objects by converting to string representation" {
            $obj = [PSCustomObject]@{ Name = "Test" }
            $result = Format-LeftText -Text $obj -Width 50
            $result.Length | Should -Be 50
            $result | Should -Match " @{Name=Test}"
        }
    }

    Context "When testing edge cases and boundary conditions" {
        It "Should handle very large width values" {
            $result = Format-LeftText -Text "Small" -Width 100
            $result.Length | Should -Be 100
            $result | Should -Match "^ Small"
            $result | Should -Match " {94}$"  # 94 trailing spaces
        }

        It "Should handle width of 1 with single character" {
            $result = Format-LeftText -Text "A" -Width 1
            $result | Should -Be " A"
            $result.Length | Should -Be 2
        }

        It "Should handle width of 2 with single character" {
            $result = Format-LeftText -Text "A" -Width 2
            $result | Should -Be " A"
            $result.Length | Should -Be 2
        }

        It "Should handle width of 3 with single character" {
            $result = Format-LeftText -Text "A" -Width 3
            $result | Should -Be " A "
            $result.Length | Should -Be 3
        }
    }

    Context "When testing string manipulation behavior" {
        It "Should always add exactly one leading space" {
            $testCases = @(
                @{ Text = "A"; Width = 10 }
                @{ Text = "Hello"; Width = 10 }
                @{ Text = "Very Long Text"; Width = 5 }
            )

            foreach ($case in $testCases) {
                $result = Format-LeftText -Text $case.Text -Width $case.Width
                $result | Should -Match "^ "  # Should always start with exactly one space
                $result.Substring(0, 1) | Should -Be " "
            }
        }

        It "Should preserve original text after leading space" {
            $originalText = "Preserve This Text"
            $result = Format-LeftText -Text $originalText -Width 30
            $result.Substring(1, $originalText.Length) | Should -Be $originalText
        }

        It "Should pad with spaces when width is larger than formatted text" {
            $result = Format-LeftText -Text "Pad" -Width 10
            $trailingPart = $result.Substring(4)  # After " Pad"
            $trailingPart | Should -Be "      "  # 6 spaces
            $trailingPart.Length | Should -Be 6
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $result = Format-LeftText -Text "Windows" -Width 15
            $result | Should -Be " Windows       "
            $result.Length | Should -Be 15
        }

        It "Should work on Linux" {
            $result = Format-LeftText -Text "Linux" -Width 12
            $result | Should -Be " Linux      "
            $result.Length | Should -Be 12
        }

        It "Should work on macOS" {
            $result = Format-LeftText -Text "macOS" -Width 10
            $result | Should -Be " macOS    "
            $result.Length | Should -Be 10
        }
    }

    Context "PowerShell 5.1 compatibility" {
        It "Should not use PowerShell 6+ only features" {
            # Verify no use of ?? operator or other PS6+ features
            $functionContent = Get-Content $PSScriptRoot\Format-LeftText.ps1 -Raw
            $functionContent | Should -Not -Match '\?\?'  # Null coalescing operator
            $functionContent | Should -Not -Match '\?\.'  # Null conditional operator
        }

        It "Should use compatible string operations" {
            # Test string concatenation and multiplication work in PS 5.1
            $result = Format-LeftText -Text "PS5.1" -Width 15
            $result | Should -Be " PS5.1         "
            $result.Length | Should -Be 15
        }

        It "Should work with older .NET Framework string handling" {
            # Test that string operations work with .NET Framework 4.x
            $result = Format-LeftText -Text "Framework" -Width 18
            $result | Should -Be " Framework        "
            $result.Length | Should -Be 18
        }

        It "Should handle string length calculations correctly" {
            # Test .Length property works correctly in PS 5.1
            $text = "Test"
            $result = Format-LeftText -Text $text -Width 10
            $result.Length | Should -Be 10
            ($result.Substring(1, $text.Length)) | Should -Be $text
        }
    }

    Context "Performance and stress testing" {
        It "Should handle multiple consecutive calls efficiently" {
            $results = @()
            for ($i = 1; $i -le 50; $i++) {
                $results += Format-LeftText -Text "Item$i" -Width 15
            }
            $results.Count | Should -Be 50
            $results[0] | Should -Be " Item1         "
            $results[49] | Should -Be " Item50        "
        }

        It "Should handle very long text efficiently" {
            $longText = "B" * 500
            $result = Format-LeftText -Text $longText -Width 100
            $result | Should -Be " $longText"
            $result.Length | Should -Be 501
        }

        It "Should handle repeated characters in padding" {
            $result = Format-LeftText -Text "X" -Width 20
            $result | Should -Be " X                  "
            $result.Length | Should -Be 20
            # Verify it's actually spaces in the padding
            $padding = $result.Substring(2)
            $padding | Should -Match "^ {18}$"
        }

        It "Should handle wide characters efficiently" {
            $result = Format-LeftText -Text "Wide" -Width 50
            $result.Length | Should -Be 50
            $result | Should -Match "^ Wide {45}$"
        }
    }

    Context "Mathematical calculations and logic" {
        It "Should calculate padding correctly for various widths" {
            $testCases = @(
                @{ Text = "Hi"; Width = 5; ExpectedPadding = 2 }    # " Hi" (3) needs 2 more
                @{ Text = "Test"; Width = 8; ExpectedPadding = 3 }  # " Test" (5) needs 3 more
                @{ Text = "A"; Width = 10; ExpectedPadding = 8 }    # " A" (2) needs 8 more
            )

            foreach ($case in $testCases) {
                $result = Format-LeftText -Text $case.Text -Width $case.Width
                $paddingLength = $result.Length - (" " + $case.Text).Length
                $paddingLength | Should -Be $case.ExpectedPadding
            }
        }

        It "Should handle boundary condition where formatted text equals width" {
            $result = Format-LeftText -Text "Exact" -Width 6
            $result | Should -Be " Exact"
            $result.Length | Should -Be 6
            # No additional padding should be added
        }

        It "Should handle the greater-than-or-equal condition correctly" {
            # Test the boundary where $Text.Length == $Width
            $result = Format-LeftText -Text "12345" -Width 6  # " 12345" = 6 chars
            $result | Should -Be " 12345"
            $result.Length | Should -Be 6

            # Test where $Text.Length > $Width
            $result2 = Format-LeftText -Text "123456" -Width 6  # " 123456" = 7 chars > 6
            $result2 | Should -Be " 123456"
            $result2.Length | Should -Be 7
        }
    }

    Context "Parameter validation behavior" {
        It "Should accept mandatory Text parameter" {
            { Format-LeftText -Text "Required" -Width 10 } | Should -Not -Throw
        }

        It "Should accept mandatory Width parameter" {
            { Format-LeftText -Text "Test" -Width 5 } | Should -Not -Throw
        }

        It "Should handle zero width gracefully" {
            $result = Format-LeftText -Text "Test" -Width 0
            $result | Should -Be " Test"
            $result.Length | Should -Be 5
        }

        It "Should handle negative width gracefully" {
            $result = Format-LeftText -Text "Test" -Width -10
            $result | Should -Be " Test"
            $result.Length | Should -Be 5
        }

        It "Should handle extremely large width values without error" {
            # Test with large but reasonable width
            $result = Format-LeftText -Text "Big" -Width 200
            $result.Length | Should -Be 200
            $result.Substring(0, 4) | Should -Be " Big"
        }
    }

    Context "String formatting consistency" {
        It "Should maintain consistent formatting pattern" {
            $testTexts = @("A", "AB", "ABC", "ABCD", "ABCDE")
            $width = 10

            foreach ($text in $testTexts) {
                $result = Format-LeftText -Text $text -Width $width
                $result.Length | Should -Be $width
                $result | Should -Match "^ $text"
                $result.Substring(0, 1) | Should -Be " "
                $result.Substring(1, $text.Length) | Should -Be $text
            }
        }

        It "Should handle whitespace-only input" {
            $result = Format-LeftText -Text "   " -Width 10
            $result | Should -Be ("    " + (" " * 6))  # " " + "   " + 6 padding spaces = 10 total spaces
            $result.Length | Should -Be 10
        }
    }
}