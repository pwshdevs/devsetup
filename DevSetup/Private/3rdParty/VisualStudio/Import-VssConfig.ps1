Function Import-VssConfig {
    param (
        [string]$EncodedConfigFile,
        [string]$VssInstallPath
    )

    if (-not $EncodedConfigFile) {
        Write-Error "Encoded configuration file is empty."
        return $false
    }

    try {
        # Decode the base64 encoded configuration
        $decodedConfig = ConvertFrom-Base64 -EncodedString $EncodedConfigFile
        
        # Create config file in user's home directory
        $configFile = Join-Path -Path $env:USERPROFILE -ChildPath ".vssconfig-devsetup"
        
        # Write the decoded configuration to the config file
        $decodedConfig | Out-File -FilePath $configFile -Encoding UTF8
        
        Write-Host "Visual Studio configuration saved to: $configFile" -ForegroundColor Green
        
        # Run the Visual Studio installer with the config file (suppress output)
        & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" modify --installPath $VssInstallPath --config "$configFile" --passive --allowUnsignedExtensions > $null 2>&1
        
        return $true
    }
    catch {
        Write-Error "Failed to process Visual Studio configuration: $_"
        return $false
    }
}