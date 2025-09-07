Function Invoke-HomebrewComponentsInstall {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$YamlData,
        [Parameter(Mandatory=$false)]
        [switch]$DryRun = $false
    )

    $packageCount = 0
    Write-HomebrewCache | Out-Null
    Write-StatusMessage "- Installing Homebrew packages from configuration:" -ForegroundColor Cyan
    foreach($package in $YamlData.devsetup.dependencies.homebrew) {
        $Params = @{
            PackageName     = $package.name
            WhatIf          = $DryRun
        }
        if ($package.PSObject.Properties.Name -contains "minimumVersion") {
            $Params.MinimumVersion = $package.minimumVersion
        }

        $status = Install-HomebrewPackage @Params

        if ($status) {
            $packageCount++
            Write-HomebrewCache | Out-Null
        }
    }
    Write-StatusMessage "- Homebrew packages installation completed! Processed $packageCount packages.`n" -ForegroundColor Green
}