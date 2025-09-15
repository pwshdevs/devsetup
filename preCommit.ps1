Import-Module Pester -ErrorAction Stop
$modifiedFiles = (git status -u -s -b | Where-Object { -not ($_ -match "^\s+D") } | Foreach-Object { $_.Substring(3) } | Where-Object { ($_ -match "^DevSetup*") -and -not ($_ -match ".Tests.ps1") })
if ($modifiedFiles.Count -gt 0) {
    Write-Host "The following DevSetup files have been modified:" -ForegroundColor DarkCyan
    $modifiedFiles | ForEach-Object { Write-Host "- $_" -ForegroundColor DarkGray }
    Write-Host ""
    foreach ($file in $modifiedFiles) {
        # Check to see if file has a .Tests.ps1 counterpart
        $testFile = $file -replace '\.ps1$', '.Tests.ps1'
        if (Test-Path $testFile) {
            Write-Host "Running tests for $file..." -ForegroundColor DarkCyan
            $TestData = ((Invoke-Pester $testFile -CodeCoverage $file -PassThru -Quiet) 2>$null 3>$null 4>$null 5>$null 6>$null)
            if($TestData.PassedCount -gt 0) {
                $passedColor = "DarkGreen"
            } else {
                $passedColor = "DarkGray"
            }
            
            if($TestData.FailedCount -gt 0) {
                $failedColor = "DarkRed"
            } else {
                $failedColor = "DarkGray"
            }
            
            if($TestData.SkippedCount -gt 0) {
                $skippedColor = "DarkYellow"
            } else {
                $skippedColor = "DarkGray"
            }

            if($TestData.Failed) {
                $TestData.Failed | ForEach-Object { Write-Host $_ -ForegroundColor DarkRed }
            }

            Write-Host "Tests Passed: $($TestData.PassedCount)," -NoNewLine -ForegroundColor $passedColor
            Write-Host " Failed: $($TestData.FailedCount)," -NoNewLine -ForegroundColor $failedColor
            Write-Host " Skipped: $($TestData.SkippedCount)," -NoNewline -ForegroundColor $skippedColor
            Write-Host " Inconclusive: $($TestData.InconclusiveCount), NotRun: $($TestData.NotRunCount)" -ForegroundColor DarkGray
            $Report = $TestData.CodeCoverage.CoverageReport
            $Coverage = $TestData.CodeCoverage.CoveragePercent
            $Target = $TestData.CodeCoverage.CoveragePercentTarget
            if($null -ne $Coverage -and $null -ne $Target) {
                if($Coverage -lt $Target) {
                    $Color = "DarkRed"
                } else {
                    $Color = "DarkGreen"
                }
            } else {
                $Color = "DarkGray"
            }
            if($Report) {
                $Report -Split "`n" | Select-Object -First 1 | Foreach-Object { Write-Host $_ -ForegroundColor $Color }
                $Report -Split "`n" | Select-Object -Skip 1 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
            }
        } else {
            Write-Host "No tests found for $file`n" -ForegroundColor DarkRed
        }
    }

} else {
    Write-Host "No modified DevSetup files detected."
}