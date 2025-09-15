Function Format-CenterText {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        [Parameter(Mandatory=$true)]
        [int]$Width
    )    

    $Text = "$Text"
    $Pad = $Width - $Text.Length
    if ($Pad -le 0) { 
        return $Text 
    }
    $Left = [math]::Floor($Pad / 2)
    $Right = $Pad - $Left
    return (' ' * $Left) + $Text + (' ' * $Right)
} 