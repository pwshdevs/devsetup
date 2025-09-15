$config = New-PesterConfiguration
#$config.Run.PassThru = $true
$config.Run.Path = "DevSetup"
$config.CodeCoverage.Path = "DevSetup"
$config.CodeCoverage.OutputFormat = "JaCoCo"
$config.CodeCoverage.OutputPath = "coverage.xml"
$config.Output.Verbosity = "Minimal"
$config.CodeCoverage.Enabled = $true
$config.TestResult.Enabled = $true
#$config.Output.Verbosity = "GithubActions"
Invoke-Pester -Configuration $config

# & 'C:\Users\TestUser\.dotnet\tools\reportgenerator.exe' -reports:"coverage.xml" -targetdir:"." -reporttypes:MarkdownSummaryGithub