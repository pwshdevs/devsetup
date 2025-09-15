Function Get-DevSetupModuleInstallPath {
    [CmdletBinding()]
    Param()

    # Get the module scope map
    $ScopeMap = Get-PowershellModuleScopeMap

    foreach ($Scope in $ScopeMap) {
        $PotentialPath = Join-Path -Path $Scope.Path -ChildPath "DevSetup"
        if (Test-Path -Path $PotentialPath) {
            return $PotentialPath
        }
    }

    return (Join-Path ($ScopeMap | Select-Object -First 1).Path -ChildPath "DevSetup")
}   