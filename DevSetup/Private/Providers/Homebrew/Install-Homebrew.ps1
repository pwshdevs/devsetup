Function Install-Homebrew {
    [CmdletBinding()]
    Param(
    )

    # Install Homebrew
    Write-StatusMessage "- Installing Homebrew package manager" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
    if (-not (Get-Command "brew" -ErrorAction SilentlyContinue)) {
        # Installation command for Homebrew (Linux/Mac)
        $installCmd = 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        (bash -c "$installCmd") *> $null
        if (-not (Get-Command "brew" -ErrorAction SilentlyContinue)) {
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            return $false
        } else {
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        }
    } else {
        Write-StatusMessage "[OK]" -ForegroundColor Green
        return $true
    }
}