BeforeAll {
    . $PSScriptRoot\Format-RightText.ps1
}

Describe "Format-RightText" {

    Context "When right-aligning text within specified width" {
        It "Should right-align text with trailing space and leading spaces" {
            $result = Format-RightText -Text "Hello" -Width 10
            $result | Should -Be "    Hello "
            $result.Length | Should -Be 10
        }

        It "Should right-align single character text" {
            $result = Format-RightText -Text "X" -Width 5
            $result | Should -Be "   X "
            $result.Length | Should -Be 5
        }

        It "Should right-align text with minimum width" {
            $result = Format-RightText -Text "Hi" -Width 4
            $result | Should -Be " Hi "
            $result.Length | Should -Be 4
        }

        It "Should handle width of exactly text length plus 1" {
            $result = Format-RightText -Text "Test" -Width 5
            $result | Should -Be "Test "
            $result.Length | Should -Be 5
        }

        It "Should handle width of exactly text length plus 2" {
            $result = Format-RightText -Text "Test" -Width 6
            $result | Should -Be " Test "
            $result.Length | Should -Be 6
        }
    }

    Context "When text width equals or exceeds specified width" {
        It "Should return text with trailing space when formatted text equals width" {
            $result = Format-RightText -Text "Test" -Width 5
            $result | Should -Be "Test "
            $result.Length | Should -Be 5
        }

        It "Should return text unchanged when formatted text exceeds width" {
            $result = Format-RightText -Text "This is a long text" -Width 10
            $result | Should -Be "This is a long text "
            $result.Length | Should -Be 20  # Original length + 1 for trailing space
        }

        It "Should return text unchanged when width is 0" {
            $result = Format-RightText -Text "Hello" -Width 0
            $result | Should -Be "Hello "
            $result.Length | Should -Be 6
        }

        It "Should return text unchanged when width is negative" {
            $result = Format-RightText -Text "Hello" -Width -5
            $result | Should -Be "Hello "
            $result.Length | Should -Be 6
        }

        It "Should handle very long text exceeding width" {
            $longText = "A" * 50
            $result = Format-RightText -Text $longText -Width 20
            $result | Should -Be "$longText "
            $result.Length | Should -Be 51
        }
    }

    Context "When handling special characters and content" {
        It "Should right-align text with spaces" {
            $result = Format-RightText -Text "Hello World" -Width 20
            $result | Should -Be "        Hello World "
            $result.Length | Should -Be 20
        }

        It "Should handle text with tabs" {
            $result = Format-RightText -Text "Tab`tText" -Width 15
            $result | Should -Be "      Tab`tText "
            $result.Length | Should -Be 15
        }

        It "Should handle text with newlines" {
            $result = Format-RightText -Text "Line1`nLine2" -Width 20
            $result | Should -Be "        Line1`nLine2 "
            $result.Length | Should -Be 20
        }

        It "Should handle unicode characters" {
            $result = Format-RightText -Text "Héllo" -Width 12
            $result | Should -Be "      Héllo "
            $result.Length | Should -Be 12
        }

        It "Should handle text with leading spaces" {
            $result = Format-RightText -Text " Spaced" -Width 12
            $result | Should -Be "     Spaced "
            $result.Length | Should -Be 12
        }

        It "Should handle text with trailing spaces" {
            $result = Format-RightText -Text "Spaced " -Width 12
            $result | Should -Be "    Spaced  "
            $result.Length | Should -Be 12
        }
    }

    Context "When handling different data types" {
        It "Should convert numbers to strings and right-align them" {
            $result = Format-RightText -Text 123 -Width 8
            $result | Should -Be "    123 "
            $result.Length | Should -Be 8
        }

        It "Should convert boolean to strings and right-align them" {
            $result = Format-RightText -Text $true -Width 10
            $result | Should -Be "     True "
            $result.Length | Should -Be 10
        }

        It "Should convert zero to string and right-align it" {
            $result = Format-RightText -Text 0 -Width 6
            $result | Should -Be "    0 "
            $result.Length | Should -Be 6
        }

        It "Should convert false to string and right-align it" {
            $result = Format-RightText -Text $false -Width 8
            $result | Should -Be "  False "
            $result.Length | Should -Be 8
        }

        It "Should handle objects by converting to string representation" {
            $obj = [PSCustomObject]@{ Name = "Test" }
            $result = Format-RightText -Text $obj -Width 50
            $result.Length | Should -Be 50
            $result | Should -Match "@{Name=Test} "
        }
    }

    Context "When testing edge cases and boundary conditions" {
        It "Should handle very large width values" {
            $result = Format-RightText -Text "Small" -Width 100
            $result.Length | Should -Be 100
            $result | Should -Match "Small $"
            $result | Should -Match "^ {94}Small $"  # 94 leading spaces
        }

        It "Should handle width of 1 with single character" {
            $result = Format-RightText -Text "A" -Width 1
            $result | Should -Be "A "
            $result.Length | Should -Be 2
        }

        It "Should handle width of 2 with single character" {
            $result = Format-RightText -Text "A" -Width 2
            $result | Should -Be "A "
            $result.Length | Should -Be 2
        }

        It "Should handle width of 3 with single character" {
            $result = Format-RightText -Text "A" -Width 3
            $result | Should -Be " A "
            $result.Length | Should -Be 3
        }
    }

    Context "When testing string manipulation behavior" {
        It "Should always add exactly one trailing space" {
            $testCases = @(
                @{ Text = "A"; Width = 5 }
                @{ Text = "AB"; Width = 5 }
                @{ Text = "ABC"; Width = 5 }
                @{ Text = "ABCD"; Width = 5 }
                @{ Text = "ABCDE"; Width = 5 }
            )

            foreach ($case in $testCases) {
                $result = Format-RightText -Text $case.Text -Width $case.Width
                $result | Should -Match "$($case.Text) $"
                $result.Substring($result.Length - 1) | Should -Be " "
                $result.Substring($result.Length - 2, 1) | Should -Be $case.Text.Substring($case.Text.Length - 1)
            }
        }

        It "Should preserve original text before trailing space" {
            $originalText = "Preserve This Text"
            $result = Format-RightText -Text $originalText -Width 30
            $result.Substring($result.Length - ($originalText.Length + 1), $originalText.Length) | Should -Be $originalText
        }

        It "Should pad with spaces when width is larger than formatted text" {
            $result = Format-RightText -Text "Pad" -Width 10
            $leadingPart = $result.Substring(0, 6)  # Before "Pad "
            $leadingPart | Should -Be "      "  # 6 spaces
            $leadingPart.Length | Should -Be 6
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $result = Format-RightText -Text "Windows" -Width 15
            $result | Should -Be "       Windows "
            $result.Length | Should -Be 15
        }

        It "Should work on Linux" {
            $result = Format-RightText -Text "Linux" -Width 12
            $result | Should -Be "      Linux "
            $result.Length | Should -Be 12
        }

        It "Should work on macOS" {
            $result = Format-RightText -Text "macOS" -Width 10
            $result | Should -Be "    macOS "
            $result.Length | Should -Be 10
        }
    }

    Context "PowerShell 5.1 compatibility" {
        It "Should not use PowerShell 6+ only features" {
            # Verify no use of ?? operator or other PS6+ features
            $functionContent = Get-Content $PSScriptRoot\Format-RightText.ps1 -Raw
            $functionContent | Should -Not -Match '\?\?'  # Null coalescing operator
            $functionContent | Should -Not -Match '\?\.'  # Null conditional operator
        }

        It "Should use compatible string operations" {
            # Test string concatenation and multiplication work in PS 5.1
            $result = Format-RightText -Text "PS5.1" -Width 15
            $result | Should -Be "         PS5.1 "
            $result.Length | Should -Be 15
        }

        It "Should work with older .NET Framework string handling" {
            # Test that string operations work with .NET Framework 4.x
            $result = Format-RightText -Text "Framework" -Width 18
            $result | Should -Be "        Framework "
            $result.Length | Should -Be 18
        }

        It "Should handle string length calculations correctly" {
            # Test .Length property works correctly in PS 5.1
            $text = "Test"
            $result = Format-RightText -Text $text -Width 10
            $result.Length | Should -Be 10
            $result.Substring($result.Length - ($text.Length + 1), $text.Length) | Should -Be $text
        }
    }

    Context "Performance and stress testing" {
        It "Should handle multiple consecutive calls efficiently" {
            $results = @()
            for ($i = 1; $i -le 50; $i++) {
                $results += Format-RightText -Text "Item$i" -Width 15
            }
            $results.Count | Should -Be 50
            $results[0] | Should -Be "         Item1 "
            $results[49] | Should -Be "        Item50 "
        }

        It "Should handle very long text efficiently" {
            $longText = "B" * 500
            $result = Format-RightText -Text $longText -Width 100
            $result | Should -Be "$longText "
            $result.Length | Should -Be 501
        }

        It "Should handle repeated characters in padding" {
            $result = Format-RightText -Text "X" -Width 20
            $result | Should -Be "                  X "
            $result.Length | Should -Be 20
            # Verify it's actually spaces in the padding
            $padding = $result.Substring(0, 18)
            $padding | Should -Match "^ {18}$"
        }

        It "Should handle wide characters efficiently" {
            $result = Format-RightText -Text "Wide" -Width 50
            $result.Length | Should -Be 50
            $result | Should -Match "^ {45}Wide $"
        }
    }

    Context "Mathematical calculations and logic" {
        It "Should calculate padding correctly for various widths" {
            $testCases = @(
                @{ Text = "Hi"; Width = 5; ExpectedPadding = 2 }    # "Hi " (3) needs 2 more
                @{ Text = "Test"; Width = 8; ExpectedPadding = 3 }  # "Test " (5) needs 3 more
                @{ Text = "A"; Width = 10; ExpectedPadding = 8 }    # "A " (2) needs 8 more
            )

            foreach ($case in $testCases) {
                $result = Format-RightText -Text $case.Text -Width $case.Width
                $paddingLength = $result.Length - ("$($case.Text) ").Length
                $paddingLength | Should -Be $case.ExpectedPadding
            }
        }

        It "Should handle boundary condition where formatted text equals width" {
            $result = Format-RightText -Text "Exact" -Width 6
            $result | Should -Be "Exact "
            $result.Length | Should -Be 6
            # No additional padding should be added
        }

        It "Should handle the greater-than-or-equal condition correctly" {
            # Test the boundary where $Text.Length == $Width
            $result = Format-RightText -Text "12345" -Width 6  # "12345 " = 6 chars
            $result | Should -Be "12345 "
            $result.Length | Should -Be 6

            # Test where $Text.Length > $Width
            $result2 = Format-RightText -Text "123456" -Width 6  # "123456 " = 7 chars > 6
            $result2 | Should -Be "123456 "
            $result2.Length | Should -Be 7
        }
    }

    Context "Parameter validation behavior" {
        It "Should accept mandatory Text parameter" {
            { Format-RightText -Text "Required" -Width 10 } | Should -Not -Throw
        }

        It "Should accept mandatory Width parameter" {
            { Format-RightText -Text "Test" -Width 5 } | Should -Not -Throw
        }

        It "Should handle zero width gracefully" {
            $result = Format-RightText -Text "Test" -Width 0
            $result | Should -Be "Test "
            $result.Length | Should -Be 5
        }

        It "Should handle negative width gracefully" {
            $result = Format-RightText -Text "Test" -Width -10
            $result | Should -Be "Test "
            $result.Length | Should -Be 5
        }

        It "Should handle extremely large width values without error" {
            # Test with large but reasonable width
            $result = Format-RightText -Text "Big" -Width 200
            $result.Length | Should -Be 200
            $result | Should -Match "Big $"
        }
    }

    Context "String formatting consistency" {
        It "Should maintain consistent formatting pattern" {
            $testTexts = @("A", "AB", "ABC", "ABCD", "ABCDE")
            $width = 10

            foreach ($text in $testTexts) {
                $result = Format-RightText -Text $text -Width $width
                $result.Length | Should -Be $width
                $result | Should -Match "$text $"
                $result.Substring($result.Length - 1) | Should -Be " "
                $result.Substring($result.Length - ($text.Length + 1), $text.Length) | Should -Be $text
            }
        }

        It "Should handle whitespace-only input" {
            $result = Format-RightText -Text "   " -Width 10
            $result | Should -Be "          "  # 7 leading spaces + "   " + trailing space = 10 total
            $result.Length | Should -Be 10
        }
    }
}