#-IncludeRule @("PSAvoidUsingInvokeExpression", "PSAvoidUsingConvertToSecureStringWithPlainText") `
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module PSScriptAnalyzer -ErrorAction Stop
Install-Module ConvertToSARIF -ErrorAction Stop
Import-Module ConvertToSarif
Invoke-ScriptAnalyzer `
    -Path . `
    -ExcludeRule @("PSAvoidLongLines", "PSAlignAssignmentStatement") `
    -IncludeDefaultRules `
    -Severity @("Error", "Warning") `
    -Recurse | ConvertTo-SARIF -FilePath results.sarif -IgnorePattern 'Tests'