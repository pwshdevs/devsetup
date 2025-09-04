Function Update-DevSetup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ParameterSetName="Main")]
        [switch]$Main,
        [Parameter(Mandatory=$true, ParameterSetName="Develop")]
        [switch]$Develop,
        [Parameter(Mandatory=$true, ParameterSetName="Version")]
        [string]$Version,
        [Parameter(Mandatory=$true, ParameterSetName="Latest")]
        [switch]$Latest
    )

    $RemoteVersion = Get-DevSetupVersion -Remote
    $LocalVersion = Get-DevSetupVersion -Local
    if($RemoteVersion -gt $LocalVersion) {
        Write-Host "A new version of DevSetup is available: $RemoteVersion (current version: $LocalVersion)" -ForegroundColor Yellow
    } elseif ($RemoteVersion -eq $LocalVersion) {
        Write-Host "You are already running the latest version of DevSetup: $LocalVersion" -ForegroundColor Green
        return
    } else {
        Write-Host "You are running a newer version of DevSetup ($LocalVersion) than the latest release ($RemoteVersion)" -ForegroundColor Yellow
        return
    }
    Write-Host ""
    Write-Host "- Updating list of available environments..." -ForegroundColor Cyan
    Optimize-DevSetupEnvs | Out-Null
    Write-Host "- Available environments updated successfully" -ForegroundColor Green
    Write-Host ""
}