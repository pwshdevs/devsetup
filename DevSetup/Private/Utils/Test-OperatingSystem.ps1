Function Test-OperatingSystem {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$Windows,

        [Parameter(Mandatory=$false)]
        [switch]$Linux,

        [Parameter(Mandatory=$false)]
        [switch]$MacOS
    )

    if((Get-PwshVersion).Major -lt 6) {
        $IsPS5Windows = $true
        $IsPS5Linux = $false
        $IsPS5MacOS = $false
    }

    if($Windows) {
        return ($IsPS5Windows -or $IsWindows)
    }
    if($Linux) {
        return ($IsPS5Linux -or $IsLinux)
    }
    if($MacOS) {
        return ($IsPS5MacOS -or $IsMacOS)
    }
    return $false
}