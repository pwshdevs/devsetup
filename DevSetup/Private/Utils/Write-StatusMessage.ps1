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

    if([string]::IsNullOrWhiteSpace($Message)) {
        #Write-StatusMessage "Message cannot be empty or whitespace." -Verbosity Error
        return
    }

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
            Write-EZLog -Category INF -Message $Message
            Write-Verbose @messageParams
        }
        "Debug" {
            Write-EZLog -Category INF -Message $Message
            Write-Debug @messageParams
        }
        "Warning" {
            Write-EZLog -Category WAR -Message $Message
            Write-Warning @messageParams
        }
        "Error" {
            Write-EZLog -Category ERR -Message $Message
            Write-Error @messageParams
        }
        "Default" {
            #Write-EZLog -Category INF -Message $Message
            Write-Host @messageParams
        }
    }
}