Function Test-OperatingSystem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$Windows,

        [Parameter(Mandatory=$false)]
        [switch]$Linux,

        [Parameter(Mandatory=$false)]
        [switch]$MacOS
    )

    if((Get-PwshVersion).Major -lt 6) {
        $IsWindows = $true
        $IsLinux = $false
        $IsMacOS = $false
    }

    if($Windows) {
        return $IsWindows
    }
    if($Linux) {
        return $IsLinux
    }
    if($MacOS) {
        return $IsMacOS
    }
    return $null
}