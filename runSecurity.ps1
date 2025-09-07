#-IncludeRule @("PSAvoidUsingInvokeExpression", "PSAvoidUsingConvertToSecureStringWithPlainText") `
import-module ConvertToSarif
Invoke-ScriptAnalyzer `
    -Path . `
    -ExcludeRule @("PSAvoidLongLines", "PSAlignAssignmentStatement") `
    -IncludeDefaultRules `
    -Severity @("Error", "Warning") `
    -Recurse | ConvertTo-SARIF -FilePath results.sarif -IgnorePattern 'Tests'