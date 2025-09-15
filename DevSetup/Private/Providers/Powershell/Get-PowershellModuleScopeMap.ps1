Function Get-PowershellModuleScopeMap {
    [CmdletBinding()]
    [OutputType([array])]
    Param()

    if((Test-OperatingSystem -Windows)) {
        $SearchPath = (Get-EnvironmentVariable USERPROFILE)
    } else {
        $SearchPath = (Get-EnvironmentVariable HOME)
    }

    $InstallPaths = @(
        (Get-EnvironmentVariable PSModulePath) -split ([System.IO.Path]::PathSeparator) | Where-Object { $_ -ne $null -and $_.Trim() -ne "" } | ForEach-Object { 
            $scope = if($SearchPath -and ($_ -match [regex]::Escape($SearchPath))) { "CurrentUser" } else { "AllUsers" }
            [PSCustomObject]@{ Path = $_; Scope = $scope }
        }
    )

    return $InstallPaths
}