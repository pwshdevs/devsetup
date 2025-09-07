Function Remove-File {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param([string]$Path)

    if ($PSCmdlet.ShouldProcess("git", "brew install")) {
        Remove-Item $Path
    }
}

Remove-File -Path ./converage.xml -WhatIf
Remove-File -Path ./converage.xml -Confirm