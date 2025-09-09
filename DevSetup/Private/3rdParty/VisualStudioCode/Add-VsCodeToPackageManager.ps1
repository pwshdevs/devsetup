Function Add-VsCodeToPackageManager {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Config
    )

    if ((Test-OperatingSystem -Windows)) {
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
            Write-StatusMessage "VS Code is already listed as a chocolatey package." -Verbosity Debug
            return $true
        } else {
            # Add vscode to chocolatey packages
            $YamlData.devsetup.dependencies.chocolatey.packages += @{
                name = "vscode"
                version = $null
            }
            
            try {
                $yamlOutput = $YamlData | ConvertTo-Yaml
                if ($PSCmdlet.ShouldProcess("Add To Chocolately Package List", "Update Environment")) {
                    if ($PSVersionTable.PSVersion.Major -eq 5) {
                        $yamlOutput | Out-File -FilePath $Config
                    } else {
                        $yamlOutput | Out-File -FilePath $Config -Encoding ([System.Text.Encoding]::UTF8)
                    }
                    Write-StatusMessage "- Configuration updated successfully" -Verbosity Debug
                }
                return $true
            }
            catch {
                Write-StatusMessage "Failed to save updated configuration: $_" -Verbosity Error
                Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
                return $false
            }            
        }
    } elseif (Test-OperatingSystem -Linux) {
        Write-StatusMessage "Find-VsCode is only supported on Windows at this time" -Verbosity Debug
        return $false
    } elseif (Test-OperatingSystem -MacOS) {
        Write-StatusMessage "Find-VsCode is only supported on Windows at this time" -Verbosity Debug
        return $false
    }
}