Function Get-HostArchitecture {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [cmdletbinding()]
    [OutputType([string])]
    Param()
    try {
        $systemArch = Invoke-Command -Script { [System.Environment]::Is64BitOperatingSystem }
        $architecture = if ($systemArch) { "x64" } else { "x86" }
        return $architecture
    } catch {
        return "x86"
    }
}