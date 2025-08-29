Function Get-DevSetupManifest {
    try {
        $moduleBase = (Get-Module -Name "DevSetup").ModuleBase
        if (-not $moduleBase) {
            Write-Error "DevSetup module is not installed."
            return $null
        }
        $manifestPath = Join-Path -Path $moduleBase -ChildPath "DevSetup.psd1"
        if (-not (Test-Path -Path $manifestPath)) {
            Write-Error "DevSetup module manifest not found at $manifestPath."
            return $null
        }
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        if (-not $manifest) {
            Write-Error "Failed to import DevSetup module manifest."
            return $null
        }

        # Return the manifest object
        return $manifest
    }
    catch {
        Write-Error "Failed to retrieve DevSetup manifest: $_"
        return $null
    }
}