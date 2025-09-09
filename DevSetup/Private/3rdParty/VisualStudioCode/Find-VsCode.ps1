Function Find-VsCode {
    [CmdletBinding()]
    [OutputType([string])]
    Param ()
    
    if (-not (Test-OperatingSystem -Windows)) {
        Write-StatusMessage "Find-VsCode is only supported on Windows at this time" -Verbosity Debug
        return $null
    } else {
        try {
            $codeCommand = (Get-Command code -ErrorAction SilentlyContinue).Path
            if ($codeCommand) {
                Write-StatusMessage "Found VS Code at $codeCommand" -Verbosity Debug
                return $codeCommand
            }
        } catch {
            Write-StatusMessage "Get-Command code failed: $_" -Verbosity Debug
        }

        $userPath = [string]::Format("{0}\Programs\Microsoft VS Code\bin\code.cmd", (Get-EnvironmentVariable -Name "LocalAppData"))
        $systemPath = [string]::Format("{0}\Microsoft VS Code\bin\code.cmd", (Get-EnvironmentVariable -Name "ProgramFiles"))

        if (Test-Path $userPath) {
            Write-StatusMessage "Found VS Code at $userPath" -Verbosity Debug
            return $userPath
        }
        
        if (Test-Path $systemPath) {
            Write-StatusMessage "Found VS Code at $systemPath" -Verbosity Debug
            return $systemPath
        }
    }
}