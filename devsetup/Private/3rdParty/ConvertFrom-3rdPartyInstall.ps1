Function ConvertFrom-3rdPartyInstall {
    Param(
        [string]$Config
    )

    # Convert from Visual Studio installations
    Write-Host "`nScanning Visual Studio installations..." -ForegroundColor Cyan
    if (-not (ConvertFrom-VisualStudioInstall -Config $Config)) {
        Write-Warning "Failed to convert Visual Studio installations, but continuing..."
    }
    
    # Convert from Visual Studio Code installations
    Write-Host "`nScanning Visual Studio Code installation..." -ForegroundColor Cyan
    if (-not (ConvertFrom-VisualStudioCodeInstall -Config $Config)) {
        Write-Warning "Failed to convert Visual Studio Code installation, but continuing..."
    }
}