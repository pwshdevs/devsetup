Function Format-LeftText {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        [Parameter(Mandatory=$true)]
        [int]$Width
    )    

    $Text = " $Text"
    if ($Text.Length -ge $Width) { 
        return $Text 
    }
    return $Text + (' ' * ($Width - $Text.Length))
}