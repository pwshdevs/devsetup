$config = New-PesterConfiguration
#$config.Run.PassThru = $true
$config.CodeCoverage.Enabled = $true
$config.TestResult.Enabled = $true
#$config.Output.Verbosity = "GithubActions"
Invoke-Pester -Configuration $config