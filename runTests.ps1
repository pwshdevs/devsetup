$config = New-PesterConfiguration
#$config.Run.PassThru = $true
$config.Run.ExcludePath = @("**/DevSetup.psm1", "**/DevSetup.psd1", "**/Private/Enums/**", "install.ps1", "runTests.ps1", "runSecurity.ps1", "generateDocs.ps1")
$config.CodeCoverage.Enabled = $true
$config.TestResult.Enabled = $true
#$config.Output.Verbosity = "GithubActions"
Invoke-Pester -Configuration $config