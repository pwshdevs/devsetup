Function Find-Homebrew {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
    )

    $TestPaths = @(
        '/usr/local/bin/brew',
        '/opt/homebrew/bin/brew',
        '/home/linuxbrew/.linuxbrew/bin/brew'
    )

    # Check if Homebrew is installed
    $Path = (Get-Command "brew" -ErrorAction SilentlyContinue).Path
    if ([string]::IsNullOrEmpty($Path)) {
        foreach ($p in $TestPaths) {
            if (Test-Path $p) {
                $Path = $p
                break
            }
        }
    }

    return $Path
}