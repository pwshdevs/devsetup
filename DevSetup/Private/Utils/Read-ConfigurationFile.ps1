Function Read-ConfigurationFile {
    param (
        [string]$Config 
    )
    $YamlData = ConvertFrom-Yaml (Get-Content -Path $Config -Raw)
    return $YamlData
}