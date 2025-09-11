Function Update-DevSetupEnvFile {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        $DevSetupEnvData,
        [Parameter(Mandatory=$true, Position=1)]        
        [string]$EnvFilePath
    )    

    try {
        if ($DevSetupEnvData.GetType().Name -ne 'Hashtable' -and $DevSetupEnvData.GetType().Name -ne 'PSCustomObject' -and $DevSetupEnvData.GetType().Name -ne 'OrderedDictionary') {
            Write-StatusMessage "Actual type: $($DevSetupEnvData.GetType().Name)" -Verbosity Error
            Write-StatusMessage "Invalid data format. Expected a Hashtable or PSCustomObject." -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return
        }
        $YamlContent = ConvertTo-Yaml $DevSetupEnvData
    } catch {
        Write-StatusMessage "Failed to convert data to YAML format: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return
    }
    if ($PSCmdlet.ShouldProcess($EnvFilePath, "Update Environment File")) {
        try {
            Set-Content -Path $EnvFilePath -Value $YamlContent -Encoding ([System.Text.Encoding]::UTF8) -Force
            Write-StatusMessage "Environment file updated successfully: $EnvFilePath" -Verbosity Debug
        } catch {
            Write-StatusMessage "Failed to update environment file: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return
        }
    }
    return
}