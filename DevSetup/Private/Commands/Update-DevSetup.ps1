Function Update-DevSetup {
    [CmdletBinding(DefaultParameterSetName="ReleaseInstall")]
    Param(
        [Parameter(Mandatory=$true, ParameterSetName="MainWebInstall")]
        [switch]$Main,
        [Parameter(Mandatory=$true, ParameterSetName="DevelopWebInstall")]
        [switch]$Develop,
        [Parameter(Mandatory=$false, ParameterSetName="ReleaseInstall")]
        [string]$Version = "latest"
    )

    Start-DevSetupSelfUpdate @PSBoundParameters
}