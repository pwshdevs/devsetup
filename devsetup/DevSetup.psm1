# DevSetup PowerShell Module

# Get the current module path
$ModulePath = $PSScriptRoot

# Get all function files from both Private and Public directories, excluding test files
$PrivateFunctions = Get-ChildItem -Path (Join-Path $ModulePath "Private") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Tests.ps1" }
$PrivateUtilsFunctions = Get-ChildItem -Path (Join-Path $ModulePath "Private\Utils") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Tests.ps1" }
$PrivateProvidersFunctions = Get-ChildItem -Path (Join-Path $ModulePath "Private\Providers") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Tests.ps1" }
$PrivateCommandsFunctions = Get-ChildItem -Path (Join-Path $ModulePath "Private\Commands") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Tests.ps1" }
$Private3rdpartyFunctions = Get-ChildItem -Path (Join-Path $ModulePath "Private\3rdparty") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Tests.ps1" }
$PrivateEnumsFunctions = Get-ChildItem -Path (Join-Path $ModulePath "Private\Enums") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Tests.ps1" }
$PublicFunctions = Get-ChildItem -Path (Join-Path $ModulePath "Public") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Tests.ps1" }

# Combine all function files
$AllFunctions = @()
if ($PrivateFunctions) { $AllFunctions += $PrivateFunctions }
if ($PrivateUtilsFunctions) { $AllFunctions += $PrivateUtilsFunctions }
if ($PrivateProvidersFunctions) { $AllFunctions += $PrivateProvidersFunctions }
if ($PrivateCommandsFunctions) { $AllFunctions += $PrivateCommandsFunctions }
if ($Private3rdpartyFunctions) { $AllFunctions += $Private3rdpartyFunctions }
if ($PrivateEnumsFunctions) { $AllFunctions += $PrivateEnumsFunctions }
if ($PublicFunctions) { $AllFunctions += $PublicFunctions }

# Import all functions
foreach ($FunctionFile in $AllFunctions) {
    try {
        . $FunctionFile.FullName
        Write-Verbose "Imported function from: $($FunctionFile.Name)"
    }
    catch {
        Write-Error "Failed to import function from $($FunctionFile.Name): $_"
    }
}

# Initialize global variables
if (-not $global:InstalledPackages) {
    $global:InstalledPackages = @()
}

if (-not $global:InstalledPackagesFile) {
    $global:InstalledPackagesFile = $null
}

New-Alias -Name devsetup -Value Use-DevSetup

# Export module members (functions will be exported via the manifest)
Write-Verbose "DevSetup module loaded successfully. $($AllFunctions.Count) functions imported ($($PrivateFunctions.Count) private, $($PrivateUtilsFunctions.Count) utils, $($PrivateProvidersFunctions.Count) providers, $($PrivateCommandsFunctions.Count) commands, $($Private3rdpartyFunctions.Count) 3rdparty, $($PublicFunctions.Count) public)."
