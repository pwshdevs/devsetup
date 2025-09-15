Function Uninstall-DevSetupModule {
    [CmdletBinding()]
    [OutputType([bool])]
    Param()

    $modulePath = Get-DevSetupModuleInstallPath
    if ($null -ne $modulePath -and (Test-Path -Path $modulePath)) {
        try {
            Remove-Item -Recurse -Force -Path $modulePath | Out-Null
            Write-StatusMessage "Successfully uninstalled DevSetup module from '$modulePath'." -Verbosity Debug
            return $true
        } catch {
            Write-StatusMessage "Failed to uninstall DevSetup module from '$modulePath': $_" -Verbosity Error
            return $false
        }
    } else {
        Write-StatusMessage "DevSetup module is not installed. No action taken." -Verbosity Warning
        return $true
    }
}