Function Write-StatusMessage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "Gray",
        [Parameter(Mandatory=$false)]
        [int]$Indent = 0,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Default", "Verbose", "Debug", "Warning", "Error")]
        [string]$Verbosity = "Default",
        [Parameter(Mandatory=$false)]
        [int]$Width = 0,
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine
    )

    if ($Indent -gt 0) {
        $Message = "$(' ' * $Indent)$Message"
    }

    if ($Width -gt 0) {
        if($Message.Length -gt $Width) {
            $Message = $Message.Substring(0, $Width - 3) + "...";
        } else {
            $Message = $Message.PadRight($Width, " ");
        }
    }

    $messageParams = @{ }

    if($Verbosity -eq "Default") {
        $messageParams.Object = $Message
        $messageParams.ForegroundColor = $ForegroundColor
        $messageParams.NoNewLine = $NoNewLine.IsPresent
    } else {
        $messageParams.Message = $Message
    }
    #$messageParams.Object = $Message

    switch($Verbosity) {
        "Verbose" {
            Write-Verbose @messageParams
        }
        "Debug" {
            Write-Debug @messageParams
        }
        "Warning" {
            Write-Warning @messageParams
        }
        "Error" {
            Write-Error @messageParams
        }
        "Default" {
            Write-Host @messageParams
        }
    }
}