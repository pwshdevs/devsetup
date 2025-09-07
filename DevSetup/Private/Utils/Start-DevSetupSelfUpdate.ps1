Function Start-DevSetupSelfUpdate {
    [CmdletBinding()]
    Param()

    $manifest = Get-DevSetupManifest
    if($null -eq $manifest) {
        throw "Failed to load manifest file"
    }

    $communityEnvironmentsProjectUri = $manifest.PrivateData.PSData.EnvironmentsProjectUri
    $devsetupProjectUri = $manifest.PrivateData.PSData.ProjectUri

    $currentVersion = Get-DevSetupVersion

    $devsetupCurrentReleaseInfo = Get-GitHubRelease -Uri $devsetupProjectUri | Select-Object -First 1
    $communityEnvironmentsCurrentReleaseInfo = Get-GitHubRelease -Uri $communityEnvironmentsProjectUri | Select-Object -First 1

    $devsetupCurrentReleaseVersion = [Version]::new(($devsetupCurrentReleaseInfo.name -Replace "v"))
    if($currentVersion -lt $devsetupCurrentReleaseVersion) {
        
    }
}