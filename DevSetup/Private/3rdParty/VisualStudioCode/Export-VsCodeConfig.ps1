Function Export-VsCodeConfig {
    Param(

    )

    try {
        Write-Host "    - Exporting VS Code configuration..." -ForegroundColor Gray
        
        # Check if 'code' command is available
        $codeCommand = Get-Command code -ErrorAction SilentlyContinue
        if (-not $codeCommand) {
            Write-Warning "VS Code 'code' command not found in PATH. Cannot export extensions."
            return $null
        }
        
        Write-Host "    - VS Code command found, listing extensions..." -ForegroundColor Gray
        
        # Get list of installed extensions
        try {
            $command = {
                & code --list-extensions 2>$null
            }
            $extensionsOutput = Invoke-Command -ScriptBlock $command
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to get VS Code extensions list"
                return $null
            }
            
            # Convert output to array (filter out empty lines)
            $extensionsArray = $extensionsOutput | Where-Object { $_ -and $_.Trim() -ne "" }
            
            if (-not $extensionsArray -or $extensionsArray.Count -eq 0) {
                Write-Host "    - No VS Code extensions found" -ForegroundColor Yellow
                return $null
            }
            
            Write-Host "    - Found $($extensionsArray.Count) VS Code extensions" -ForegroundColor Gray
            
            # Convert array to JSON
            $jsonData = $extensionsArray | ConvertTo-Json
            
            # Convert JSON to Base64
            $base64Config = ConvertTo-Base64 -InputString $jsonData
            
            if (-not $base64Config) {
                Write-Error "Failed to encode VS Code extensions to Base64"
                return $null
            }
            
            Write-Host "    - VS Code extensions exported and encoded successfully" -ForegroundColor Gray
            return $base64Config
        }
        catch {
            Write-Error "Error getting VS Code extensions: $_"
            return $null
        }
    }
    catch {
        Write-Error "Error exporting VS Code configuration: $_"
        return $null
    }
}