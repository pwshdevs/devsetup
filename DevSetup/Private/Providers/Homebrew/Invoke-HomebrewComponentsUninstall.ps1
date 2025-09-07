Function Invoke-HomebrewComponentsUninstall {
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
    Write-StatusMessage "- Uninstalling Homebrew packages from configuration:" -ForegroundColor Cyan
    foreach($package in $YamlData.devsetup.dependencies.homebrew) {
        $Params = @{
            PackageName     = $package.name
            WhatIf          = $DryRun
        }

        $status = Uninstall-HomebrewPackage @Params

        if ($status) {
            $packageCount++
            Write-HomebrewCache | Out-Null
        }
    }
    Write-StatusMessage "- Homebrew packages uninstallation completed! Processed $packageCount packages.`n" -ForegroundColor Green
}