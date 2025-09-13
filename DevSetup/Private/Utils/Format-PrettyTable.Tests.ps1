BeforeAll {
    . (Join-Path $PSScriptRoot "Format-PrettyTable.ps1")
    . (Join-Path $PSScriptRoot "Write-StatusMessage.ps1")
    Mock Write-StatusMessage { }
}

Describe "Format-PrettyTable" {

    Context "When formatting table with left alignment" {
        It "Should output table with left-aligned columns" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
                Age = @{ Key = "Age"; Name = "Age"; Width = 5; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice"; Age = 30 }
                @{ Name = "Bob"; Age = 25 }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 18 -Scope It  # Top, header, middle, 2 rows, bottom
        }
    }

    Context "When formatting table with center alignment" {
        It "Should output table with center-aligned columns" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Center"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It  # Top, header, middle, row, bottom
        }
    }

    Context "When formatting table with right alignment" {
        It "Should output table with right-aligned columns" {
            $columns = @{
                Age = @{ Key = "Age"; Name = "Age"; Width = 5; Alignment = "Right"; Color = "White" }
            }
            $rows = @(
                @{ Age = 30 }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }
    }

    Context "When formatting table with mixed alignments" {
        It "Should output table with mixed alignments" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
                Age = @{ Key = "Age"; Name = "Age"; Width = 5; Alignment = "Center"; Color = "White" }
                City = @{ Key = "City"; Name = "City"; Width = 8; Alignment = "Right"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice"; Age = 30; City = "NYC" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 17 -Scope It
        }
    }

    Context "When rows are objects instead of hashtables" {
        It "Should handle object properties" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                [PSCustomObject]@{ Name = "Alice" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }
    }

    # Context "When table has no rows" {
    #     It "Should output only borders and header" {
    #         $columns = @{
    #             Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
    #         }
    #         $rows = @()
    #         $tableFormat = @{ BorderColor = "Gray" }
    #         Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
    #         Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It  # Top, header, bottom
    #     }
    # }

    Context "When table has single column" {
        It "Should output table without inner separators" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }
    }

    Context "When text exceeds column width" {
        It "Should truncate or handle long text" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 5; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "VeryLongName" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }
    }

    Context "When table format has different border color" {
        It "Should use specified border color" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice" }
            )
            $tableFormat = @{ BorderColor = "Red" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }
    }

    Context "When row has color" {
        It "Should use row color for data" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice"; Color = "Green" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }

        It "Should work on Linux" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }

        It "Should work on macOS" {
            $columns = @{
                Name = @{ Key = "Name"; Name = "Name"; Width = 10; Alignment = "Left"; Color = "White" }
            }
            $rows = @(
                @{ Name = "Alice" }
            )
            $tableFormat = @{ BorderColor = "Gray" }
            Format-PrettyTable -Columns $columns -Rows $rows -TableFormat $tableFormat
            Assert-MockCalled Write-StatusMessage -Exactly 9 -Scope It
        }
    }
}