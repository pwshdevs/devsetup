Function Get-DevSetupUpdateUri {
    [CmdletBinding(DefaultParameterSetName="ReleaseInstall")]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MainWebInstall")]
        [switch]$Main,
        [Parameter(Mandatory=$true, ParameterSetName="DevelopWebInstall")]
        [switch]$Develop,
        [Parameter(Mandatory=$false, ParameterSetName="ReleaseInstall")]
        [string]$Version = "latest"
    )

    $Uri = $null
    $VersionToInstall = $null
    if($PSBoundParameters.ContainsKey('Main')) {
        # Install the main branch
        Write-StatusMessage "Main branch selected." -Verbosity Debug
        $Uri = "https://github.com/pwshdevs/devsetup/archive/main.zip"
        $VersionToInstall = "main"
    } elseif($PSBoundParameters.ContainsKey('Develop')) {
        # Install the develop branch
        Write-StatusMessage "Development branch selected. This may be unstable." -Verbosity Debug
        $Uri = "https://github.com/pwshdevs/devsetup/archive/develop.zip"
        $VersionToInstall = "develop"
    } else {
        if( [string]::IsNullOrEmpty($Version)) {
            $Version = "latest"
        }
        Write-StatusMessage "Fetching release information from GitHub..." -Verbosity Debug
        # Download the the most current release and install that
        $Releases = (Invoke-WebRequest -Uri https://api.github.com/repos/pwshdevs/devsetup/releases -usebasicparsing).Content | convertfrom-json
        Write-StatusMessage "Fetched $(($Releases | Measure-Object).Count) releases from GitHub." -Verbosity Debug
        Write-StatusMessage "Looking for version: $Version" -Verbosity Debug
        if($Version -eq "latest") {
            $Uri = $Releases | Select-Object -First 1 | ForEach-Object { $_.zipball_url }
            $VersionToInstall = "latest"
        } else {
            $Uri = $Releases | Foreach-Object { if($_.tag_name -eq "v$Version") { $_.zipball_url } }
            if([string]::IsNullOrEmpty($Uri)) {
                Write-StatusMessage "No release found matching version: $Version" -Verbosity Error
                return $null
            }
            $VersionToInstall = $Version
        }
    }

    return @{
        Uri = $Uri
        Version = $VersionToInstall
    }
}