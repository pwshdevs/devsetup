Function Update-DevSetup {
    [CmdletBinding()]
    Param()

    Write-Host ""
    Write-Host "- Updating list of available environments..." -ForegroundColor Cyan
    Optimize-DevSetupEnvs | Out-Null
    Write-Host "- Available environments updated successfully" -ForegroundColor Green
    Write-Host ""
}