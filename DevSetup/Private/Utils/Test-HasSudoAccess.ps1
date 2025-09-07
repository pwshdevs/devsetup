Function Test-HasSudoAccess {
    [CmdletBinding()]
    Param(
    )

    # Try running a harmless command with sudo
    (bash -c "sudo -n true") *>$null
    if ($LASTEXITCODE -eq 0) {
        return $true
    } else {
        return $false
    }
}