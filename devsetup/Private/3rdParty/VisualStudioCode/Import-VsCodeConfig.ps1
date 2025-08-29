Function Import-VsCodeConfig {
    Param(
        [string]$EncodedConfig
    )

    try {
        Write-Host "- Importing VS Code configuration..." -ForegroundColor Gray
        
        if (-not $EncodedConfig) {
            Write-Warning "No encoded configuration provided"
            return $false
        }
        
        # Check if 'code' command is available
        $codeCommand = Get-Command code -ErrorAction SilentlyContinue
        $codePath = $null
        
        if ($codeCommand) {
            $codePath = "code"
            Write-Host "  - VS Code command found in PATH" -ForegroundColor Gray
        }
        else {
            # Manual path checks when code command is not in PATH
            $userPath = "$env:LocalAppData\Programs\Microsoft VS Code\bin\code.cmd"
            $systemPath = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
            
            if (Test-Path $userPath) {
                $codePath = $userPath
                Write-Host "  - VS Code found at user path: $userPath" -ForegroundColor Gray
            }
            elseif (Test-Path $systemPath) {
                $codePath = $systemPath
                Write-Host "  - VS Code found at system path: $systemPath" -ForegroundColor Gray
            }
        }
        
        if (-not $codePath) {
            Write-Warning "VS Code executable not found. Cannot install extensions."        
            return $false
        }
        
        Write-Host "  - VS Code command found, decoding configuration..." -ForegroundColor Gray
        
        # Decode the base64 configuration
        $decodedJson = ConvertFrom-Base64 -EncodedString $EncodedConfig
        if (-not $decodedJson) {
            Write-Error "Failed to decode base64 configuration"
            return $false
        }
        
        Write-Host "  - Configuration decoded, parsing JSON..." -ForegroundColor Gray
        
        # Convert from JSON
        try {
            $extensions = $decodedJson | ConvertFrom-Json
        }
        catch {
            Write-Error "Failed to parse JSON from decoded configuration: $_"
            return $false
        }
        
        # Handle both array and single string cases
        if ($extensions -is [string]) {
            # Single extension
            $extensionList = @($extensions)
        }
        elseif ($extensions -is [array]) {
            # Array of extensions
            $extensionList = $extensions
        }
        else {
            Write-Error "Unexpected extension data type: $($extensions.GetType())"
            return $false
        }
        
        if ($extensionList.Count -eq 0) {
            Write-Host "  - No extensions to install" -ForegroundColor Yellow
            return $true
        }
        
        Write-Host "  - Installing $($extensionList.Count) VS Code extensions..." -ForegroundColor Gray
        
        $successCount = 0
        $failureCount = 0
        
        # Install each extension
        foreach ($extension in $extensionList) {
            if (-not $extension -or $extension.Trim() -eq "") {
                continue
            }
            
            Write-Host "    - Installing extension: $extension" -ForegroundColor Gray
            
            try {
                $command = {
                    & $codePath --install-extension $extension --force 2>&1
                }
                $result = Invoke-Command -ScriptBlock $command
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "      - Successfully installed: $extension" -ForegroundColor Green
                    $successCount++
                }
                else {
                    Write-Warning "      - Failed to install: $extension - $result"
                    $failureCount++
                }
            }
            catch {
                Write-Warning "      - Error installing: $extension - $_"
                $failureCount++
            }
        }
        
        # Summary
        Write-Host "  - Extension installation complete: $successCount successful, $failureCount failed" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Error "Error importing VS Code configuration: $_"
        return $false
    }
}