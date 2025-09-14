<#
.SYNOPSIS
    Retrieves all package dependencies from installed Chocolatey packages.

.DESCRIPTION
    This function scans all installed Chocolatey packages and extracts their dependency information
    by parsing the .nuspec files in the Chocolatey lib directory. It reads the XML metadata from
    each package's nuspec file and collects all non-Chocolatey dependencies into a consolidated
    list. The function automatically filters out Chocolatey-specific dependencies to focus on
    actual package dependencies.

.OUTPUTS
    [System.Array]
    Returns an array of package dependency names (strings) found across all installed packages.
    Returns an empty array if no dependencies are found or Chocolatey is not installed.

.EXAMPLE
    Get-ChocolateyPackageDependencies
    
    Returns all package dependencies from installed Chocolatey packages.

.EXAMPLE
    $dependencies = Get-ChocolateyPackageDependencies
    if ($dependencies.Count -gt 0) {
        Write-Host "Found $($dependencies.Count) dependencies"
        $dependencies | ForEach-Object { Write-Host "- $_" }
    }
    
    Demonstrates retrieving and displaying all package dependencies.

.EXAMPLE
    $allDeps = Get-ChocolateyPackageDependencies
    $uniqueDeps = $allDeps | Select-Object -Unique | Sort-Object
    
    Gets all dependencies and creates a sorted list of unique dependency names.

.NOTES
    - Requires Chocolatey to be installed with packages in the standard lib directory
    - Uses $Env:ChocolateyInstall environment variable to locate the Chocolatey installation
    - Scans all .nuspec files recursively in the Chocolatey lib directory
    - Parses XML metadata from nuspec files to extract dependency information
    - Automatically filters out dependencies with IDs starting with "chocolatey" (Chocolatey system packages)
    - Returns all dependencies in a flat array, including duplicates from multiple packages
    - Provides debug logging for troubleshooting package discovery issues
    - Returns empty array gracefully if Chocolatey installation path is not found
    - Uses ForEach-Object (%) for efficient processing of large package collections

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Dependency Analysis, Package Management, Metadata Extraction
#>

Function Get-ChocolateyPackageDependencyMap {
    [CmdletBinding()]
    [OutputType([array])]
    Param()

    Write-StatusMessage "Retrieving Chocolatey package dependencies..." -Verbosity Debug
    $packageDependencies = @()

    try {
        $ChocolateyInstallEnvPath = Get-EnvironmentVariable ChocolateyInstall
    } catch {
        Write-StatusMessage "Error retrieving ChocolateyInstall environment variable: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $chocolateyInstallPath = Join-Path $ChocolateyInstallEnvPath lib
    } catch {
        Write-StatusMessage "Error constructing Chocolatey lib path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        if (-not (Test-Path $chocolateyInstallPath)) {
            Write-StatusMessage "Chocolatey installation path not found: $chocolateyInstallPath" -Verbosity Debug
            return $null
        }
    } catch {
        Write-StatusMessage "Error testing Chocolatey lib path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $packageDependencies = Get-ChildItem $chocolateyInstallPath -Recurse "*.nuspec" | ForEach-Object {
            ([xml](Get-Content $_.FullName)).package.metadata.dependencies.dependency | ForEach-Object {
                if (-not ($_.id -like "chocolatey*")) {
                    $_.id
                }
            }
        }
        if(-not $packageDependencies) {
            return $null
        }
    } catch {
            Write-StatusMessage "Error processing nuspec files: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $null
    }
    return [array]$packageDependencies
}