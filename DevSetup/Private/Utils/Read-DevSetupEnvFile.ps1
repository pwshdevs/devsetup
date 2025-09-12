Function Read-DevSetupEnvFile {
    param (
        [string]$Config 
    )
    
    $YamlData = ConvertFrom-Yaml -Ordered (Get-Content -Path $Config -Raw)
    
    # Handle null case - validation function expects non-null input
    if ($null -eq $YamlData) {
        throw "Configuration file '$Config' is empty or returned null data."
    }
    
    # Validate the structure before returning - this will throw if invalid
    Assert-DevSetupEnvValid -EnvData $YamlData
    
    return $YamlData
}