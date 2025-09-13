Function Invoke-VsCodeExtensionsExport {
    [CmdletBinding()]
    [OutputType([string])]
    Param()

    try {
        # Check if 'code' command is available
        $codeCommand = Find-VsCode
        if (-not $codeCommand) {
            Write-StatusMessage "Visual Studio Code 'code' command not found in PATH. Cannot export extensions." -Verbosity Debug
            return $null
        }

        # Get list of installed extensions
        try {
            $extensionsOutput = Invoke-Command -ScriptBlock { & $codeCommand --list-extensions --show-versions 2>$null }
            if ($LASTEXITCODE -ne 0) {
                Write-StatusMessage "Failed to get Visual Studio Code extensions list" -Verbosity Debug
                return $null
            }
            
            # Convert output to array (filter out empty lines)
            $extensionsArray = $extensionsOutput | Where-Object { $_ -and $_.Trim() -ne "" }
            
            if (-not $extensionsArray -or $extensionsArray.Count -eq 0) {
                Write-StatusMessage "- No Visual Studio Code extensions found" -Indent 2 -Verbosity Debug
                return $null
            }

            Write-StatusMessage "- Found $($extensionsArray.Count) Visual Studio Code extensions" -Indent 2 -Verbosity Debug

            # Convert array to JSON
            $jsonData = $extensionsArray | ConvertTo-Json
            return $jsonData
        } catch {
            Write-StatusMessage "Error getting Visual Studio Code extensions: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $null
        }
    } catch {
        Write-StatusMessage "Error exporting Visual Studio Code configuration: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }
}