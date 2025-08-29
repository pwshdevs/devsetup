Function ConvertFrom-VisualStudioInstall {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Config,
        [string]$OutFile,
        [switch]$DryRun
    )

    try {
        # Check if running as administrator
        if (-not (Test-RunningAsAdmin)) {
            throw "This operation requires administrator privileges. Please run as administrator."
        }

        # Get Visual Studio instances
        Write-Host "- Detecting Visual Studio installations..." -ForegroundColor Gray
        $vsInstances = Get-VSSetupInstance
        
        if (-not $vsInstances) {
            Write-Warning "No Visual Studio instances found."
            return $true
        }

        # Read existing YAML configuration
        $YamlData = Read-ConfigurationFile -Config $Config

        # Ensure chocolateyPackages section exists
        if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
        if (-not $YamlData.devsetup.commands) { $YamlData.devsetup.commands = @() }
        if (-not $YamlData.devsetup.dependencies) { $YamlData.devsetup.dependencies = @{} }
        if (-not $YamlData.devsetup.dependencies.chocolatey) { $YamlData.devsetup.dependencies.chocolatey = @{} }
        if (-not $YamlData.devsetup.dependencies.chocolatey.packages) { $YamlData.devsetup.dependencies.chocolatey.packages = @() }
        
        foreach ($instance in $vsInstances) {
            Write-Host "  - Found: $($instance.DisplayName)" -ForegroundColor Gray

            # Convert display name to Chocolatey package name
            # Extract year and type separately to ensure correct ordering
            $displayName = $instance.DisplayName
            $year = if ($displayName -match '(\d{4})') { $matches[1] } else { '' }
            $type = ''
            if ($displayName -match 'Community') { $type = 'community' }
            elseif ($displayName -match 'Professional') { $type = 'professional' }
            elseif ($displayName -match 'Enterprise') { $type = 'enterprise' }
            
            # Build package name as visualstudio<year><type>
            $packageName = "visualstudio$year$type"
            
            Write-Host "    - Converted to Chocolatey package: $packageName" -ForegroundColor Gray

            # Create temporary file for Visual Studio configuration export
            $base64Config = Export-VssConfig -VssInstallPath $instance.InstallationPath

            # Create command string for importing the VS configuration
            $Command = "Import-VssConfig -EncodedConfigFile '$base64Config' -VssInstallPath '$($instance.InstallationPath)'"
            $commandPackageName = "$packageName.importConfig"
            
            # Check if command already exists for this package
            $existingCommand = $YamlData.devsetup.commands | Where-Object { 
                ($_ -is [hashtable] -and $_.packageName -eq $commandPackageName)
            }
            
            if ($existingCommand) {
                Write-Host "    - Updating existing VS configuration command..." -ForegroundColor Gray
                
                # Find index of existing command
                $commandIndex = $YamlData.devsetup.commands.IndexOf($existingCommand)
                
                # Update with new command
                $YamlData.devsetup.commands[$commandIndex] = @{
                    packageName = $commandPackageName
                    command = $Command
                }
            } else {
                Write-Host "    - Adding new VS configuration command..." -ForegroundColor Gray
                
                # Add new command
                $YamlData.devsetup.commands += @{
                    packageName = $commandPackageName
                    command = $Command
                }
            }

            $existingPackage = $YamlData.devsetup.dependencies.chocolatey.packages | Where-Object { 
                ($_ -is [string] -and $_ -eq $packageName) -or 
                ($_ -is [hashtable] -and $_.name -eq $packageName)
            }

            if ($existingPackage) {
                Write-Host "    - Updating existing Visual Studio packages..." -ForegroundColor Gray
                
                # Find index of existing package
                $index = $YamlData.devsetup.dependencies.chocolatey.packages.IndexOf($existingPackage)

                # Update with components
                $YamlData.devsetup.dependencies.chocolatey.packages[$index] = @{
                    name = $packageName
                    version = $null
                }
            } else {
                Write-Host "    - Adding new Visual Studio package..." -ForegroundColor Gray
                
                # Add new package with components
                $YamlData.devsetup.dependencies.chocolatey.packages += @{
                    name = $packageName
                    version = $null
                }
            }           
        }

        try {
            $yamlOutput = $YamlData | ConvertTo-Yaml
        }
        catch {
            Write-Warning "Could not convert to YAML format. Showing PowerShell object instead:"
            $yamlOutput = $YamlData | ConvertTo-Json -Depth 10
        }

        # Handle output based on parameters
        if ($DryRun) {
            Write-Host "`nDry Run - Configuration would be saved as:" -ForegroundColor Cyan
            Write-Host $yamlOutput -ForegroundColor White
            Write-Host "`nNo files were modified (dry run mode)." -ForegroundColor Yellow
        } else {
            # Determine output file
            $outputFile = if ($OutFile) { $OutFile } else { $Config }
            
            try {
                Write-Debug "`nSaving configuration to: $outputFile"
                $yamlOutput | Out-File -FilePath $outputFile -Encoding UTF8
                Write-Debug "Configuration saved successfully!"
            }
            catch {
                Write-Error "Failed to save configuration to $outputFile`: $_"
                return $false
            }
        }

        # "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" export --installPath "<path_to_VS_installation>" --config "<filename>.vsconfig"
        # "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" modify --installPath "C:\Program Files\Microsoft Visual Studio\<Version>\<Edition>" --config "C:\Path\To\Your\Config.vsconfig" --passive --allowUnsignedExtensions

        Write-Host "Visual Studio installation conversion completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error in Visual Studio installation conversion: $_"
        return $false
    }    
}