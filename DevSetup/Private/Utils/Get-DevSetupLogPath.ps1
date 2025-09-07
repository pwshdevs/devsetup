Function Get-DevSetupLogPath {
    [CmdletBinding()]
    param (
    )

    $LogPath = Join-Path -Path (Get-DevSetupPath) -ChildPath "logs"

    if (-not (Test-Path -Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath | Out-Null
    }

    return $LogPath
}