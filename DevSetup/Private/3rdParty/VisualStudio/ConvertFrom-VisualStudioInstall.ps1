Function ConvertFrom-VisualStudioInstall {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Config,
        [switch]$DryRun
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "This operation requires administrator privileges. Please run as administrator."
        }

        # Get Visual Studio instances
        Write-StatusMessage "- Detecting Visual Studio installations..." -ForegroundColor Gray
        $vsInstances = Get-VSSetupInstance
        
        if (-not $vsInstances) {
            Write-StatusMessage "No Visual Studio instances found." -Verbosity Warning
            return $true
        }
        
        foreach ($instance in $vsInstances) {
            $packageName = Add-VsToPackageManager -Instance $instance -Config $Config -DryRun:$DryRun

            # Read existing YAML configuration
            $YamlData = Read-DevSetupEnvFile -Config $Config

            # Ensure commands section exists
            if (-not $YamlData.devsetup.commands) { $YamlData.devsetup.commands = @() }  

            # Create temporary file for Visual Studio configuration export
            $VsConfig = Invoke-VsConfigExport -VsInstallPath $instance.InstallationPath

            # Create command string for importing the VS configuration
            $Command = "Invoke-VsConfigImport"
            $Params = @{
                config = $VsConfig
                vsinstallpath = $instance.InstallationPath
            }
            $oldCommandPackageName = "$packageName.importConfig"
            $CommandPackageName = "invoke.vs.config.import.$packageName"
            
            # Check if command already exists for this package
            $existingCommand = $YamlData.devsetup.commands | Where-Object { 
                ($_.packageName -eq $oldCommandPackageName -or $_.packageName -eq $CommandPackageName)
            }
            
            if ($existingCommand) {
                Write-StatusMessage "- Updating existing VS configuration command..." -ForegroundColor Gray -Indent 4 -NoNewline -Width 112

                # Find index of existing command
                $commandIndex = $YamlData.devsetup.commands.IndexOf($existingCommand)
                
                # Update with new command
                $YamlData.devsetup.commands[$commandIndex] = @{
                    packageName = $CommandPackageName
                    command = $Command
                    params = $Params
                }
            } else {
                Write-StatusMessage "- Adding new VS configuration command..." -ForegroundColor Gray -Indent 4 -NoNewline -Width 112

                # Add new command
                $YamlData.devsetup.commands += @{
                    packageName = $CommandPackageName
                    command = $Command
                    params = $Params
                }
            }

            try {
                Write-StatusMessage "`nSaving configuration to: $Config" -Verbosity Debug
                Write-StatusMessage "[OK]" -ForegroundColor Green
                $YamlData | Update-DevSetupEnvFile -EnvFilePath $Config -WhatIf:$DryRun
            }
            catch {
                Write-StatusMessage "Failed to save configuration to $Config`: $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                return $false
            }                    
        }

        Write-StatusMessage "Visual Studio installation conversion completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-StatusMessage "Error in Visual Studio installation conversion: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }    
}