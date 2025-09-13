Function Invoke-VsCodeExtensionsImport {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Extensions,
        [Parameter(Mandatory=$false)]
        [string]$LogFile = $null
    )

    if (-not ([string]::IsNullOrEmpty($LogFile))) {
        $PSDefaultParameterValues = @{
            'Write-EZLog:LogFile'   = $LogFile ;
        }
    }

    try {
        if (-not $Extensions) {
            Write-StatusMessage "No extensions provided" -Verbosity Warning
            return $false
        }
        
        $codePath = Find-VsCode
        if (-not $codePath) {
            Write-StatusMessage "Visual Studio Code executable not found" -Verbosity Error
            return $false
        }
        
        # Convert from JSON
        try {
            $ExtensionList = ($Extensions | ConvertFrom-Json)
        }
        catch {
            Write-StatusMessage "Failed to parse JSON from decoded configuration: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }
        
        if (-not $ExtensionList) {
            Write-StatusMessage "No extensions found in provided configuration" -Verbosity Warning
            return $true
        }

        # Handle both array and single string cases
        if (-not ($ExtensionList -is [array])) {
            if ($ExtensionList -is [string]) {
                $ExtensionList = @($ExtensionList)
            } else {
                Write-StatusMessage "Unexpected extension data type: $($ExtensionList.GetType())" -Verbosity Error
                return $false
            }
        }

        Write-StatusMessage "- Installing $($ExtensionList.Count) Visual Studio Code extensions..." -ForegroundColor Gray -Indent 4

        $successCount = 0
        $failureCount = 0
        
        # Install each extension
        foreach ($Extension in $ExtensionList) {
            if(([string]::IsNullOrEmpty(($Extension.Trim())))) {
                Write-StatusMessage "- Skipping empty extension entry" -ForegroundColor Yellow -Verbosity Warning
                continue
            }

            Write-StatusMessage "- Installing extension: $Extension" -ForegroundColor Gray -Width 112 -NoNewLine -Indent 6
            
            try {
                Invoke-Command -ScriptBlock { & $codePath --install-extension $Extension --force } *> $null
                if ($LASTEXITCODE -eq 0) {
                    Write-StatusMessage "[OK]" -ForegroundColor Green
                    $successCount++
                }
                else {
                    Write-StatusMessage "[FAILED]" -ForegroundColor Red
                    $failureCount++
                }
            }
            catch {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
                Write-StatusMessage "Error installing: $Extension - $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                $failureCount++
            }
        }
        
        # Summary
        Write-StatusMessage "- Extension installation complete: $successCount successful, $failureCount failed" -ForegroundColor Gray -Indent 4
        
        return $true
    } catch {
        Write-StatusMessage "Error importing VS Code configuration: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}