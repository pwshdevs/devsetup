Function Get-PwshVersion {
    [CmdletBinding()]
    Param()

    return @{
        Major = $PSVersionTable.PSVersion.Major
        Minor = $PSVersionTable.PSVersion.Minor
        Patch = $PSVersionTable.PSVersion.Build
    }
}