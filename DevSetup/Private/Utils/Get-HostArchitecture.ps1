Function Get-HostArchitecture {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    [OutputType([string])]
    Param()

    $architecture = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    return $architecture
}