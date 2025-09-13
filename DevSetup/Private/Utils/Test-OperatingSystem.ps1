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
        if ($Windows) {
            return $true
        } else {
            return $false
        }
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
    return $false
}