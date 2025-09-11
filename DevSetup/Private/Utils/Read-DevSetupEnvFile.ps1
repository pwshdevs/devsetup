Function Read-DevSetupEnvFile {
    param (
        [string]$Config 
    )
    $YamlData = ConvertFrom-Yaml -Ordered (Get-Content -Path $Config -Raw)
    return $YamlData
}