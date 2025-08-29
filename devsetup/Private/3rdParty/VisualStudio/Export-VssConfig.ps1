Function Export-VssConfig {
    param (
        [string]$VssInstallPath
    )

    if (-not (Test-Path -Path $VssInstallPath)) {
        Write-Error "Visual Studio installation path not found: $VssInstallPath"
        return $false
    }

    try {
        $tempConfigFile = [System.IO.Path]::GetTempFileName() + ".vsconfig"
        
        # Execute the command
        & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" export --installPath $VssInstallPath --config "$tempConfigFile" --passive
        
        # Since setup.exe is async, wait for the config file to be created and populated
        $timeout = 60 # seconds
        $elapsed = 0
        $pollInterval = 2 # seconds
        
        Write-Host "    - Waiting for Visual Studio export to complete." -ForegroundColor Gray -NoNewline
        
        while ($elapsed -lt $timeout) {
            if ((Test-Path -Path $tempConfigFile) -and (Get-Item $tempConfigFile).Length -gt 0) {
                Write-Host "`n    - Export completed successfully." -ForegroundColor Gray
                break
            }
            Start-Sleep -Seconds $pollInterval
            $elapsed += $pollInterval
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
        
        # Check if we timed out
        if ($elapsed -ge $timeout) {
            Write-Host "    - Export operation timed out after $timeout seconds." -ForegroundColor Gray
            Write-Warning "Visual Studio export may still be running in the background. Check the installation manually."
        }
        
        if (-not (Test-Path -Path $tempConfigFile)) {
            Write-Error "Failed to export Visual Studio configuration to temporary file."
            return $false
        }

        $encodedConfig = ConvertTo-Base64 -FilePath $tempConfigFile
        if (-not $encodedConfig) {
            Write-Error "Failed to convert configuration file to Base64."
            return $false
        }
        
        # Clean up temporary files
        if (Test-Path $tempConfigFile) { Remove-Item $tempConfigFile -Force }
        
        return $encodedConfig
    } catch {
        Write-Error "Failed to export configuration to file: $_"
        return $false
    }
}