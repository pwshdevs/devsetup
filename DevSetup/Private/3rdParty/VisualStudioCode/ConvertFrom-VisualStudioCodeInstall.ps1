Function ConvertFrom-VisualStudioCodeInstall {
    Param (
        [string]$Config
    )

    try {
        Write-Host "- Detecting Visual Studio Code installation..." -ForegroundColor Gray
        
        # Read existing configuration
        $YamlData = Read-ConfigurationFile -Config $Config
        
        # Ensure chocolateyPackages section exists
        if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
        if (-not $YamlData.devsetup.dependencies) { $YamlData.devsetup.dependencies = @{} }
        if (-not $YamlData.devsetup.dependencies.chocolatey) { $YamlData.devsetup.dependencies.chocolatey = @{} }
        if (-not $YamlData.devsetup.dependencies.chocolatey.packages) { $YamlData.devsetup.dependencies.chocolatey.packages = @() }
        
        # Check if vscode is already in chocolatey packages
        $existingVscodePackage = $YamlData.devsetup.dependencies.chocolatey.packages | Where-Object { 
            ($_ -is [string] -and $_ -eq "vscode") -or 
            ($_ -is [hashtable] -and $_.name -eq "vscode")
        }
        
        if ($existingVscodePackage) {
            Write-Host "  - Visual Studio Code already configured in chocolatey packages" -ForegroundColor Green
            
            # Export VS Code configuration
            Write-Host "  - Exporting VS Code configuration..." -ForegroundColor Gray
            $encodedConfig = Export-VsCodeConfig
            
            if ($encodedConfig) {
                # Ensure commands section exists
                if (-not $YamlData.devsetup.commands) { $YamlData.devsetup.commands = @() }
                
                # Check if vscode.importConfig command already exists
                $existingCommand = $YamlData.devsetup.commands | Where-Object { 
                    ($_ -is [hashtable] -and $_.packageName -eq "vscode.importConfig") 
                }
                
                if ($existingCommand) {
                    # Update existing command with new encoded config
                    $existingCommand.command = "Import-VsCodeConfig -EncodedConfig $encodedConfig"
                    Write-Host "  - VS Code import command updated in configuration" -ForegroundColor Green
                }
                else {
                    # Add new Import-VsCodeConfig command
                    $YamlData.devsetup.commands += @{
                        command = "Import-VsCodeConfig -EncodedConfig '$encodedConfig'"
                        packageName = "vscode.importConfig"
                    }
                    Write-Host "  - VS Code import command added to configuration" -ForegroundColor Green
                }
                
                # Save updated configuration
                try {
                    $yamlOutput = $YamlData | ConvertTo-Yaml
                    $yamlOutput | Out-File -FilePath $Config -Encoding UTF8
                    Write-Host "  - Configuration updated successfully" -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to save updated configuration: $_"
                    return $false
                }
            }
            else {
                Write-Host "  - No VS Code configuration to export" -ForegroundColor Yellow
            }
            
            return $true
        }
        
        # Check for manual installation using multiple methods
        $vscodeInstalled = $false
        $detectionMethod = ""
        
        # Method 1: Check if 'code --version' works
        try {
            $codeVersion = & code --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $codeVersion) {
                $vscodeInstalled = $true
                $detectionMethod = "command line (code --version)"
                Write-Host "  - Found VS Code via command line: $($codeVersion[0])" -ForegroundColor Gray
            }
        }
        catch {
            # Command not found, continue with other methods
        }
        
        # Method 2: Check registry
        if (-not $vscodeInstalled) {
            try {
                $regPath = "HKLM:\SOFTWARE\Classes\Applications\Code.exe\shell\open\command"
                $regValue = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                if ($regValue) {
                    $vscodeInstalled = $true
                    $detectionMethod = "registry"
                    Write-Host "  - Found VS Code via registry" -ForegroundColor Gray
                }
            }
            catch {
                # Registry check failed, continue
            }
        }
        
        # Method 3: Filesystem checks
        if (-not $vscodeInstalled) {
            $userPath = "$env:LocalAppData\Programs\Microsoft VS Code\bin\code.cmd"
            $systemPath = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
            
            if (Test-Path $userPath) {
                $vscodeInstalled = $true
                $detectionMethod = "user installation path"
                Write-Host "  - Found VS Code at: $userPath" -ForegroundColor Gray
            }
            elseif (Test-Path $systemPath) {
                $vscodeInstalled = $true
                $detectionMethod = "system installation path"
                Write-Host "  - Found VS Code at: $systemPath" -ForegroundColor Gray
            }
        }
        
        # Method 4: Get-Package check
        if (-not $vscodeInstalled) {
            try {
                $package = Get-Package -Name "*vscode*" -ErrorAction SilentlyContinue
                if ($package) {
                    $vscodeInstalled = $true
                    $detectionMethod = "package manager"
                    Write-Host "  - Found VS Code via Get-Package: $($package.Name)" -ForegroundColor Gray
                }
            }
            catch {
                # Get-Package failed, continue
            }
        }
        
        if ($vscodeInstalled) {
            Write-Host "  - Visual Studio Code detected ($detectionMethod), adding to chocolatey packages" -ForegroundColor Green
            
            # Add vscode to chocolatey packages
            $YamlData.devsetup.dependencies.chocolatey.packages += @{
                name = "vscode"
                version = $null
            }
            
            # Export VS Code configuration
            Write-Host "  - Exporting VS Code configuration..." -ForegroundColor Gray
            $encodedConfig = Export-VsCodeConfig
            
            if ($encodedConfig) {
                # Ensure commands section exists
                if (-not $YamlData.devsetup.commands) { $YamlData.devsetup.commands = @() }
                
                # Add Import-VsCodeConfig command
                $YamlData.devsetup.commands += @{
                    command = "Import-VsCodeConfig -EncodedConfig '$encodedConfig'"
                    packageName = "vscode.importConfig"
                }
                Write-Host "  - VS Code import command added to configuration" -ForegroundColor Green
            }
            else {
                Write-Host "  - No VS Code configuration to export" -ForegroundColor Yellow
            }
            
            # Save updated configuration
            try {
                $yamlOutput = $YamlData | ConvertTo-Yaml
                $yamlOutput | Out-File -FilePath $Config -Encoding UTF8
                Write-Host "  - Configuration updated successfully" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to save updated configuration: $_"
                return $false
            }
        }
        else {
            Write-Host "  - Visual Studio Code not detected on this system" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Error "Error detecting Visual Studio Code installation: $_"
        return $false
    }
}