$moduleRoot = ".\DevSetup" # Adjust as needed
$manifestPath = Join-Path $moduleRoot "DevSetup.psd1" # Adjust as needed

# Create backup of the manifest file
$backupPath = "$manifestPath.backup"
Copy-Item -Path $manifestPath -Destination $backupPath -Force
Write-Host "Created backup: $backupPath" -ForegroundColor Green

try {
    $functionNames = @()
    Get-ChildItem -Path $moduleRoot -Filter "*.ps1" -Recurse | ForEach-Object {
        $functionNames += $_.BaseName
    }

    # Remove duplicates and sort for consistency
    $functionNames = $functionNames | Select-Object -Unique | Sort-Object

    # Read the original manifest
    $manifest = Import-PowerShellDataFile $manifestPath

    # Create a new manifest with updated FunctionsToExport
    New-ModuleManifest -Path $manifestPath `
        -RootModule $manifest.RootModule `
        -ModuleVersion $manifest.ModuleVersion `
        -GUID $manifest.GUID `
        -Author $manifest.Author `
        -CompanyName $manifest.CompanyName `
        -Copyright $manifest.Copyright `
        -Description $manifest.Description `
        -PowerShellVersion $manifest.PowerShellVersion `
        -FunctionsToExport $functionNames `
        -CmdletsToExport $manifest.CmdletsToExport `
        -VariablesToExport $manifest.VariablesToExport

    $markdownPath = '.\DevSetup\docs'
    $mamlPath = '.\DevSetup\en-US'

    # Import module by manifest path instead of name
    $importedModule = Import-Module -Name $manifestPath -Force -PassThru

    # Get the module name for the documentation
    $moduleName = $importedModule.Name

    $mdHelpParams = @{
         Module                = $moduleName  # Use module name, not path
         OutputFolder          = $markdownPath
         AlphabeticParamsOrder = $true
         UseFullTypeName       = $true
         WithModulePage        = $true
         ExcludeDontShow       = $false
         Encoding              = [System.Text.Encoding]::UTF8
     }
     New-MarkdownHelp @mdHelpParams
     Update-MarkdownHelp -Path $markdownPath

     $extHelpParams = @{
        Path = $markdownPath
        OutputPath = $mamlPath
    }
    New-ExternalHelp @extHelpParams

    Write-Host "Documentation generation completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Documentation generation failed: $($_.Exception.Message)"
}
finally {
    # Restore the original manifest file from backup
    if (Test-Path $backupPath) {
        Copy-Item -Path $backupPath -Destination $manifestPath -Force
        Remove-Item -Path $backupPath -Force
        Write-Host "Restored original manifest and cleaned up backup" -ForegroundColor Yellow
    }
}