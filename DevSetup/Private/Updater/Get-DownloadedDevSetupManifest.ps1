Function Get-DownloadedDevSetupManifest {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModulePath
    )

    if(-not (Test-Path $ModulePath)) {
        Write-StatusMessage "Module path not found: $ModulePath" -Verbosity Error
        return $null
    }

    if(-not (Get-Item $ModulePath).PSIsContainer) {
        Write-StatusMessage "Module path is not a directory: $ModulePath" -Verbosity Error
        return $null
    }

    $ModuleManifestPath = Join-Path -Path $ModulePath -ChildPath "DevSetup.psd1"
    if(-not (Test-Path $ModuleManifestPath)) {
        Write-StatusMessage "Module manifest not found at path: $ModuleManifestPath" -Verbosity Error
        return $null
    }

    try {
        $ModuleManifest = Import-PowerShellDataFile -Path $ModuleManifestPath
        if(-not $ModuleManifest -or -not $ModuleManifest.ModuleVersion) {
            Write-StatusMessage "Failed to read version from module manifest at path: $ModuleManifestPath" -Verbosity Error
            return $null
        }
        return $ModuleManifest
    } catch {
        Write-StatusMessage "Error reading module manifest at path: $ModuleManifestPath - $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }
}