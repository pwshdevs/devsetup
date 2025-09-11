Function Add-VsToPackageManager {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        [Parameter(Mandatory=$true)]
        $Instance,
        [Parameter(Mandatory=$true)]
        [string]$Config,
        [switch]$DryRun
    )

    $YamlData = Read-DevSetupEnvFile -Config $Config

    # Ensure chocolateyPackages section exists
    if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
    if (-not $YamlData.devsetup.dependencies) { $YamlData.devsetup.dependencies = @{} }
    if (-not $YamlData.devsetup.dependencies.chocolatey) { $YamlData.devsetup.dependencies.chocolatey = @{} }
    if (-not $YamlData.devsetup.dependencies.chocolatey.packages) { $YamlData.devsetup.dependencies.chocolatey.packages = @() }

    Write-StatusMessage "- Found: $($instance.DisplayName)" -ForegroundColor Gray -Indent 2

    # Convert display name to Chocolatey package name
    # Extract year and type separately to ensure correct ordering
    $displayName = $instance.DisplayName
    $year = $null
    if ($displayName -match '(\d{4})') { 
        $year = $matches[1] 
    }

    if (-not $year) {
        Write-StatusMessage "- Unable to determine Visual Studio year from display name: $displayName" -ForegroundColor Yellow -Indent 4
        return $null
    }

    $type = $null
    if ($displayName -match 'Community') { 
        $type = 'community' 
    } elseif ($displayName -match 'Professional') { 
        $type = 'professional' 
    } elseif ($displayName -match 'Enterprise') { 
        $type = 'enterprise' 
    }
    
    if (-not $type) {
        Write-StatusMessage "- Unable to determine Visual Studio type from display name: $displayName" -ForegroundColor Yellow -Indent 4
        return $null
    }

    # Build package name as visualstudio<year><type>
    $packageName = "visualstudio$year$type"

    Write-StatusMessage "- Adding $displayName to package manager..." -ForegroundColor Gray -Indent 4 -NoNewLine -Width 112

    $existingPackage = $YamlData.devsetup.dependencies.chocolatey.packages | Where-Object { 
        ($_ -is [string] -and $_ -eq $packageName) -or 
        ($_.name -eq $packageName)
    }

    if ($existingPackage) {
        Write-StatusMessage "[OK]" -ForegroundColor Green
        Write-StatusMessage "Visual Studio is already listed as a chocolatey package." -Verbosity Debug
        return $packageName
    } else {
        # Add new package with components
        $YamlData.devsetup.dependencies.chocolatey.packages += @{
            name = $packageName
            version = $null
        }
    }  
    
    try {
        $YamlData | Update-DevSetupEnvFile -EnvFilePath $Config -WhatIf:$DryRun
        Write-StatusMessage "[OK]" -ForegroundColor Green
        return $packageName
    } catch {
        Write-StatusMessage "Error updating DevSetup environment file: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        Write-StatusMessage "[FAILED]" -ForegroundColor Green
        return $null
    }
}