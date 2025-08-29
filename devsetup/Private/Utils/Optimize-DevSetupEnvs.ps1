Function Optimize-DevSetupEnvs {
    try {
        # Get the DevSetup environments path
        $envPath = Get-DevSetupEnvPath
        if (-not $envPath -or -not (Test-Path $envPath)) {
            Write-Warning "DevSetup environments path not found or doesn't exist: $envPath"
            return $false
        }
        
        # Get all YAML files in the environments path
        $yamlFiles = Get-ChildItem -Path $envPath -Filter "*.yaml" -File
        if (-not $yamlFiles) {
            #Write-Host "No YAML environment files found in: $envPath" -ForegroundColor Yellow
            Write-StatusMessage "- Indexing 0 environment files" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline | Out-Null
            Write-StatusMessage "[OK]" -ForegroundColor Green | Out-Null
            return $true
        }
        
        #Write-Host "Found $($yamlFiles.Count) environment file(s) to process..." -ForegroundColor Cyan
        Write-StatusMessage "- Indexing $($yamlFiles.Count) environment files" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline | Out-Null

        $environments = @()
        
        foreach ($yamlFile in $yamlFiles) {
            try {
                Write-Debug "Processing: $($yamlFile.Name)"
                
                # Read the YAML configuration
                $config = Read-ConfigurationFile -Config $yamlFile.FullName
                
                # Extract environment name (filename without extension)
                $envName = [System.IO.Path]::GetFileNameWithoutExtension($yamlFile.Name)
                
                # Extract platform information
                $platform = $null
                if ($config -and $config.devsetup -and $config.devsetup.configuration -and $config.devsetup.configuration.os -and $config.devsetup.configuration.os.name) {
                    $platform = $config.devsetup.configuration.os.name
                }
                
                # Extract version information
                $version = "Unknown"
                if ($config -and $config.devsetup -and $config.devsetup.configuration -and $config.devsetup.configuration -and $config.devsetup.configuration.version) {
                    $version = $config.devsetup.configuration.version
                }
                
                # Create environment entry
                $envEntry = @{
                    name = $envName
                    platform = $platform
                    version = $version
                    file = $yamlFile.Name
                }
                
                $environments += $envEntry
                $platformDisplay = if ($platform) { $platform } else { 'Not specified' }
                Write-Debug "  - Name: $envName, Version: $version, Platform: $platformDisplay"
            }
            catch {
                Write-Warning "Failed to process $($yamlFile.Name): $_"
                continue
            }
        }
        
        # Write results to environments.json
        $devSetupPath = Get-DevSetupPath
        $environmentsJsonPath = Join-Path -Path $devSetupPath -ChildPath "environments.json"
        
        try {
            $jsonOutput = $environments | ConvertTo-Json -Depth 10
            $jsonOutput | Out-File -FilePath $environmentsJsonPath -Encoding UTF8
            Write-Debug "Environment index written to: $environmentsJsonPath"
            #Write-Host "Processed $($environments.Count) environment(s) successfully" -ForegroundColor Green
            Write-StatusMessage "[OK]" -ForegroundColor Green
        }
        catch {
            Write-StatusMessage "[Failed]" -ForegroundColor Red
            return $false
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to optimize DevSetup environments: $_"
        return $false
    }
}