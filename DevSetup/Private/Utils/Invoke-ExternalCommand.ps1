Function Invoke-ExternalCommand {
    [System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute()]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Command,
        [Parameter()]
        [string[]]$Arguments
    )

    # Build the full command line
    $cmdLine = $Command
    if ($Arguments) {
        $cmdLine += " " + ($Arguments -join " ")
    }

    # Invoke the command and capture output
    if ($Arguments -and $Arguments.Count -gt 0) {
        $output = & $Command @Arguments 2>&1
    } else {
        $output = & $Command 2>&1
    }
    return $output
}