Function ConvertFrom-VisualStudioCodeInstall {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    Param (
        [string]$Config
    )

    try {
        Write-StatusMessage "- Detecting Visual Studio Code installation..." -ForegroundColor Gray
        
        # Read existing configuration
        $YamlData = Read-ConfigurationFile -Config $Config
        
        # Ensure chocolateyPackages section exists
        if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
        if (-not $YamlData.devsetup.commands) { $YamlData.devsetup.commands = @() }

        $vsCode = Find-VsCode

        if ($vsCode) {
            Write-StatusMessage "- Adding Visual Studio Code to package manager" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
            $packageAddStatus = Add-VsCodeToPackageManager -Config $Config -WhatIf:$WhatIf
            if ($packageAddStatus) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
            } else {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
                return $false
            }

            Write-StatusMessage "- Exporting Visual Studio Code extensions..." -Indent 2 -ForegroundColor Gray -Width 77 -NoNewline
            $extensions = Invoke-VsCodeExtensionsExport

            if ($extensions) {
                Write-StatusMessage "[OK]" -ForegroundColor Green
                # Check if import.vscode.extensions command already exists
                $existingCommand = $YamlData.devsetup.commands | Where-Object { 
                    ($_ -is [hashtable] -and ($_.packageName -eq "invoke.vs.code.extensions.import" -or $_.packageName -eq "vscode.importConfig"))
                }
                
                if ($existingCommand) {
                    # Update existing command with new encoded config
                    $existingCommand.command = "Invoke-VsCodeExtensionsImport"
                    $existingCommand.packageName = "invoke.vs.code.extensions.import"
                    $existingCommand.params = @{
                        extensions = $extensions
                    }
                    Write-StatusMessage "- Updating Visual Studio Code import command..." -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
                } else {
                    # Add new Invoke-VsCodeExtensionsImport command
                    $YamlData.devsetup.commands += @{
                        command = "Invoke-VsCodeExtensionsImport"
                        packageName = "import.vscode.extensions"
                        params = @{
                            extensions = $extensions
                        }
                    }
                    Write-StatusMessage "- Adding Visual Studio Code import command..." -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
                }
                
                # Save updated configuration
                try {
                    if ($PSCmdlet.ShouldProcess("Add to devsetup commands list", "Update Environment")) {
                        $yamlOutput = $YamlData | ConvertTo-Yaml
                        if ($PSVersionTable.PSVersion.Major -eq 5) {
                            $yamlOutput | Out-File -FilePath $Config
                        } else {
                            $yamlOutput | Out-File -FilePath $Config -Encoding ([System.Text.Encoding]::UTF8)
                        }
                        Write-StatusMessage "[OK]" -ForegroundColor Green
                    }
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