Function Test-HomebrewPackageInstalled {
    [CmdletBinding()]
    [OutputType([InstalledState])]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$PackageName,
        [Parameter(Mandatory=$false, Position=1)]
        [Version]$MinimumVersion
    )

    [InstalledState]$PackageStatus = [InstalledState]::NotInstalled

    if(-not (Test-HomebrewInstalled)) {
        Write-StatusMessage "Homebrew is not installed" -Verbosity Verbose
        return $PackageStatus
    }

    $InstalledPackages = Read-HomebrewCache

    if ($InstalledPackages.ContainsKey($PackageName)) {
        $PackageStatus += [InstalledState]::Installed

        if($PSBoundParameters.ContainsKey('MinimumVersion')) {
            $MinimumVersion = [Version]::Parse($MinimumVersion)
            $InstalledVersion = [Version]::Parse($InstalledPackages[$PackageName])
            if ($InstalledVersion -ge $MinimumVersion) {
                $PackageStatus += [InstalledState]::MinimumVersionMet
                $PackageStatus += [InstalledState]::RequiredVersionMet
                $PackageStatus += [InstalledState]::GlobalVersionMet
            }
        } else {
            $PackageStatus += [InstalledState]::MinimumVersionMet
            $PackageStatus += [InstalledState]::RequiredVersionMet
            $PackageStatus += [InstalledState]::GlobalVersionMet
        }
    }

    return $PackageStatus
}