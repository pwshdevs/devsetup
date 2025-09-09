Function Format-PrettyTable {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $Columns,
        [Parameter(Mandatory=$true)]
        [array]$Rows,
        [Parameter(Mandatory=$true)] 
        [hashtable]$TableFormat
    )

    # Double-line for outer edges
    $edgeV  = [char]0x2551 # ║
    $edgeH  = [char]0x2550 # ═
    $edgeTL = [char]0x2554 # ╔
    $edgeTR = [char]0x2557 # ╗
    $edgeBL = [char]0x255A # ╚
    $edgeBR = [char]0x255D # ╝

    $sepTD = [char]0x2564 # ╥
    $sepBU = [char]0x2567 # ╧
    $sepMD = [char]0x256A # ╪

    # Light single-line for inner separators
    $sepV   = [char]0x2502 # │
    #$sepH   = [char]0x2500 # ─
    #$sepT   = [char]0x252C # ┬
    #$sepM   = [char]0x253C # ┼
    #$sepB   = [char]0x2534 # ┴

    function Write-RepeatChar($char, $count) { -join (1..$count | ForEach-Object { $char }) }
    function Write-CenterText($text, $width) {
        $text = "$text"
        $pad = $width - $text.Length
        if ($pad -le 0) { return $text }
        $left = [math]::Floor($pad / 2)
        $right = $pad - $left
        (' ' * $left) + $text + (' ' * $right)
    }   

    function Write-LeftText($text, $width) {
        $text = " $text"
        if ($text.Length -ge $width) { return $text }
        return $text + (' ' * ($width - $text.Length))
    }

    function Write-RightText($text, $width) {
        $text = "$text "
        if ($text.Length -ge $width) { return $text }
        return (' ' * ($width - $text.Length)) + $text
    }    

    # Top border: double corners, light separators
    $topBorder = $edgeTL
    $middleBorder = $edgeV
    $bottomBorder = $edgeBL

    $idx = 0;
    foreach ($column in $Columns.Values) {
        $topBorder += (Write-RepeatChar $edgeH $column.Width)
        $middleBorder += (Write-RepeatChar $edgeH $column.Width)
        $bottomBorder += (Write-RepeatChar $edgeH $column.Width)

        if ($idx -lt $Columns.Count -1) {
            # Add light separators
            $topBorder += $sepTD
            $middleBorder += $sepMD
            $bottomBorder += $sepBU
        }
        $idx++
    }

    $topBorder += $edgeTR
    $middleBorder += $edgeV
    $bottomBorder += $edgeBR

    Write-StatusMessage $topBorder -ForegroundColor $TableFormat.BorderColor
    Write-StatusMessage $edgeV -ForegroundColor $TableFormat.BorderColor -NoNewLine

    $idx = 0;
    foreach ($column in $Columns.Values) {
        $columnText = switch ($column.Alignment) {
            "Left"   { Write-LeftText $column.Name $column.Width }
            "Center" { Write-CenterText $column.Name $column.Width }
            "Right"  { Write-RightText $column.Name $column.Width }
            default  { $column.Name }
        }

        Write-StatusMessage $columnText -ForegroundColor $column.Color -NoNewLine

        if ($idx -lt $Columns.Count -1) {
            Write-StatusMessage $sepV -ForegroundColor $TableFormat.BorderColor -NoNewLine
        }
        $idx++
    }

    Write-StatusMessage $edgeV -ForegroundColor $TableFormat.BorderColor

    Write-StatusMessage $middleBorder -ForegroundColor $TableFormat.BorderColor

    foreach ($row in $Rows) {
        Write-StatusMessage $edgeV -ForegroundColor $TableFormat.BorderColor -NoNewLine
        $idx = 0;
        foreach ($column in $Columns.Values) {
            if ($row -is [hashtable]) {
                $value = $row[$column.Key]
            } else {
                $value = $row.($column.Key)
            }

            $columnText = switch ($column.Alignment) {
                "Left"   { Write-LeftText $value $column.Width }
                "Center" { Write-CenterText $value $column.Width }
                "Right"  { Write-RightText $value $column.Width }
                default  { $value }
            }

            Write-StatusMessage $columnText -ForegroundColor $row.Color -NoNewLine

            if ($idx -lt $Columns.Count -1) {
                Write-StatusMessage $sepV -ForegroundColor $TableFormat.BorderColor -NoNewLine
            }
            $idx++
        }
        Write-StatusMessage $edgeV -ForegroundColor $TableFormat.BorderColor
    }

    Write-StatusMessage $bottomBorder -ForegroundColor $TableFormat.BorderColor

}