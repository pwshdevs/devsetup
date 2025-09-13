Function ConvertFrom-VisualStudioCodeInstall {
    [CmdletBinding()]
    [OutputType([bool])]
    Param (
        [string]$Config,
        [switch]$DryRun
    )

    try {
        Write-StatusMessage "- Detecting Visual Studio Code installation..." -ForegroundColor Gray
        
        # Read existing configuration
        $YamlData = Read-DevSetupEnvFile -Config $Config
        
        # Ensure commands section exists
        if (-not $YamlData.devsetup.commands) { $YamlData.devsetup.commands = @() }

        $vsCode = Find-VsCode

        if ($vsCode) {
            Write-StatusMessage "- Adding Visual Studio Code to package manager" -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
            $packageAddStatus = Add-VsCodeToPackageManager -Config $Config -DryRun:$DryRun
            if ($packageAddStatus) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
                return $false
            }

            Write-StatusMessage "- Exporting Visual Studio Code extensions..." -Indent 2 -ForegroundColor Gray -Width 112 -NoNewline
            $extensions = Invoke-VsCodeExtensionsExport

            if ($extensions) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
                # Check if import.vscode.extensions command already exists
                $existingCommand = $YamlData.devsetup.commands | Where-Object { 
                    ($_.packageName -eq "invoke.vs.code.extensions.import" -or $_.packageName -eq "vscode.importConfig")
                }
                
                if ($existingCommand) {
                    $commandIndex = $YamlData.devsetup.commands.IndexOf($existingCommand)
                    # Update existing command with new encoded config
                    $YamlData.devsetup.commands[$commandIndex] = @{
                        packageName = "invoke.vs.code.extensions.import"
                        command = "Invoke-VsCodeExtensionsImport"
                        params = @{
                            extensions = $extensions
                        }
                    }                    
                    Write-StatusMessage "- Updating Visual Studio Code import command..." -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
                } else {
                    # Add new Invoke-VsCodeExtensionsImport command
                    $YamlData.devsetup.commands += @{
                        command = "Invoke-VsCodeExtensionsImport"
                        packageName = "invoke.vs.code.extensions.import"
                        params = @{
                            extensions = $extensions
                        }
                    }
                    Write-StatusMessage "- Adding Visual Studio Code import command..." -ForegroundColor Gray -Indent 2 -Width 112 -NoNewline
                }
                
                # Save updated configuration
                try {
                    Write-StatusMessage "[OK]" -ForegroundColor Green
                    $YamlData | Update-DevSetupEnvFile -EnvFilePath $Config -WhatIf:$DryRun
                } catch {
                    Write-StatusMessage "Failed to save updated devsetup environment: $_" -Verbosity Error
                    Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                    return $false
                }
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
            }
            
            Write-StatusMessage "Visual Studio Code installation conversion completed!" -ForegroundColor Green
            return $true
        } else {
            Write-StatusMessage "- Visual Studio Code not detected, skipping extension export" -ForegroundColor Yellow -Indent 2
            return $true
        }
    } catch {
        Write-StatusMessage "Error detecting Visual Studio Code installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}