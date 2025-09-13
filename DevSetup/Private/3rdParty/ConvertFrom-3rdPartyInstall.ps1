Function ConvertFrom-3rdPartyInstall {
    Param(
        [string]$Config,
        [switch]$DryRun
    )

    if((Test-OperatingSystem -Windows)) {
        # Convert from Visual Studio installations
        Write-Host "`nScanning for Visual Studio installations..." -ForegroundColor Cyan
        if (-not (ConvertFrom-VisualStudioInstall -Config $Config -DryRun:$DryRun)) {
            Write-Warning "Failed to convert Visual Studio installations, but continuing..."
        }
    
        # Convert from Visual Studio Code installations
        Write-Host "`nScanning for Visual Studio Code installation..." -ForegroundColor Cyan
        if (-not (ConvertFrom-VisualStudioCodeInstall -Config $Config -DryRun:$DryRun)) {
            Write-Warning "Failed to convert Visual Studio Code installation, but continuing..."
        }
    }
}