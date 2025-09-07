Function Optimize-DevSetupEnvs {
    [CmdletBinding()]
    [OutputType([bool])]
    Param()
    try {
        # Get the DevSetup environments path
        $envPath = Get-DevSetupEnvPath
        if (-not $envPath -or -not (Test-Path $envPath)) {
            Write-StatusMessage "DevSetup environments path not found or doesn't exist: $envPath" -Verbosity Warning
            return $false
        }
        
        # Get all YAML files in the environments path
        $devsetupEnvFiles = Get-ChildItem -Path $envPath -Filter "*.devsetup" -File -Recurse
        if (-not $devsetupEnvFiles) {
            #Write-Host "No YAML environment files found in: $envPath" -ForegroundColor Yellow
            Write-StatusMessage "- Indexing 0 environment files" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline | Out-Null
            Write-StatusMessage "[OK]" -ForegroundColor Green | Out-Null
            return $true
        }
        
        #Write-Host "Found $($yamlFiles.Count) environment file(s) to process..." -ForegroundColor Cyan
        Write-StatusMessage "- Indexing $($devsetupEnvFiles.Count) environment files" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline | Out-Null

        $environments = @()
        
        foreach ($devsetupEnvFile in $devsetupEnvFiles) {
            try {
                Write-Debug "Processing: $($devsetupEnvFile.Name)"
                
                # Read the YAML configuration
                $config = Read-ConfigurationFile -Config $devsetupEnvFile.FullName
                
                # Extract environment name (filename without extension)
                $envName = [System.IO.Path]::GetFileNameWithoutExtension($devsetupEnvFile.Name)
                
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

                $provider = ($devsetupEnvFile.FullName.Split([System.IO.Path]::DirectorySeparatorChar))[-2]

                if($provider -ne 'local') {
                    $envName = $provider + ":" + $envName
                }
                
                # Create environment entry
                $envEntry = @{
                    name = $envName
                    platform = $platform
                    version = $version
                    file = $devsetupEnvFile.Name
                    provider = $provider
                }
                
                $environments += $envEntry
                $platformDisplay = if ($platform) { $platform } else { 'Not specified' }
                Write-StatusMessage "  - Name: $envName, Version: $version, Platform: $platformDisplay" -Verbosity Debug
            }
            catch {
                Write-StatusMessage "Failed to process $($devsetupEnvFile.Name): $_" -Verbosity Warning
                continue
            }
        }
        
        # Write results to environments.json
        $devSetupPath = Get-DevSetupPath
        $environmentsJsonPath = Join-Path -Path $devSetupPath -ChildPath "environments.json"
        
        try {
            $jsonOutput = $environments | ConvertTo-Json -Depth 10
            $jsonOutput | Out-File -FilePath $environmentsJsonPath
            Write-StatusMessage "Environment index written to: $environmentsJsonPath" -Verbosity Debug
            Write-StatusMessage "[OK]" -ForegroundColor Green
        }
        catch {
            Write-StatusMessage "Failed to optimize DevSetup environments: $_" -ForegroundColor Red -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace  -Verbosity Error
            return $false
        }
        
        return $true
    }
    catch {
        Write-StatusMessage "Failed to optimize DevSetup environments: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}