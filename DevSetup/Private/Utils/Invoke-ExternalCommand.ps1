Function Invoke-ExternalCommand {
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
    $output = & $Command @Arguments 2>&1
    return $output
}