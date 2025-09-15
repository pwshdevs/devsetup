# Helper functions for working with YAML-parsed data structures
function Test-DictionaryLike {
    param($obj)
    return ($obj -is [hashtable] -or $obj.GetType().Name -eq 'Hashtable') -or 
           ($obj -is [PSCustomObject] -or $obj.GetType().Name -eq 'PSCustomObject') -or
           ($obj -is [System.Collections.Specialized.OrderedDictionary] -or $obj.GetType().Name -eq 'OrderedDictionary')
}

function Test-KeyExists {
    param($obj, $key)
    if ($obj -is [hashtable]) {
        return $obj.ContainsKey($key)
    } elseif ($obj -is [System.Collections.Specialized.OrderedDictionary]) {
        return $obj.Contains($key)
    } elseif ($obj -is [PSCustomObject]) {
        return [bool]($obj.PSObject.Properties.Name -contains $key)
    }
    return $false
}

function Get-Value {
    param($obj, $key)
    if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) {
        $value = $obj[$key]
        # Preserve arrays and Lists using unary comma
        if ($value -is [array] -or $value -is [System.Collections.Generic.List[System.Object]]) {
            return ,$value
        }
        return $value
    } elseif ($obj -is [PSCustomObject]) {
        $value = $obj.$key
        # Preserve arrays and Lists using unary comma
        if ($value -is [array] -or $value -is [System.Collections.Generic.List[System.Object]]) {
            return ,$value
        }
        return $value
    }
    return $null
}

function ConvertTo-NormalizedArray {
    <#
    .SYNOPSIS
    Converts various YAML parsing artifacts to a normalized PowerShell array
    
    .DESCRIPTION
    YAML parsing can result in PSCustomObjects with numeric properties, hashtables with numeric keys,
    or Lists. This function normalizes all these formats to a standard PowerShell array.
    #>
    param(
        $InputObject,
        [string]$Context = "array"
    )
    
    # Handle null input
    if ($null -eq $InputObject) {
        return ,@()  # Use unary comma to prevent empty array unwrapping
    }
    
    # Handle already normalized arrays first
    if ($InputObject -is [array]) {
        Write-Debug "ConvertTo-NormalizedArray: Input is already an array, returning as-is"
        return ,$InputObject  # Use unary comma to prevent array unwrapping
    }
    
    # Handle PSCustomObject with numeric properties (YAML array artifact)
    if ($InputObject -is [PSCustomObject]) {
        $properties = $InputObject.PSObject.Properties.Name
        $numericProperties = $properties | Where-Object { $_ -match '^\d+$' }
        if ($numericProperties.Count -eq $properties.Count -and $properties.Count -gt 0) {
            # Convert PSCustomObject with numeric properties to array
            $result = @($properties | Sort-Object { [int]$_ } | ForEach-Object { $InputObject.$_ })
            return ,$result  # Use unary comma to prevent array unwrapping
        }
        else {
            # Single PSCustomObject item - wrap in array
            return ,@($InputObject)
        }
    }
    
    # Handle hashtable with numeric keys (YAML array artifact)
    elseif ($InputObject -is [hashtable]) {
        $keys = $InputObject.Keys
        $numericKeys = $keys | Where-Object { $_ -match '^\d+$' }
        if ($numericKeys.Count -eq $keys.Count -and $keys.Count -gt 0) {
            # Convert hashtable with numeric keys to array
            $result = @($keys | Sort-Object { [int]$_ } | ForEach-Object { $InputObject[$_] })
            return ,$result  # Use unary comma to prevent array unwrapping
        }
        else {
            # Single hashtable item - wrap in array
            return ,@($InputObject)
        }
    }
    
    # Handle List<T> objects from YAML parsing
    elseif ($InputObject -is [System.Collections.Generic.List[System.Object]]) {
        $result = $InputObject.ToArray()
        return ,$result  # Use unary comma to prevent array unwrapping
    }
    
    # Handle other single items - return as-is for validation to catch invalid types
    else {
        return $InputObject
    }
}

function Assert-ConfigurationValid {
    <#
    .SYNOPSIS
    Validates the configuration section of a devsetup environment
    #>
    param(
        $Configuration,
        [string]$Context = "configuration"
    )
    
    if (-not (Test-DictionaryLike $Configuration)) {
        throw "'$Context' must be a hashtable or PSCustomObject."
    }
    
    # Required configuration fields (must be present, can be empty or null)
    $requiredConfigFields = @('createdBy', 'description', 'lastModified', 'createdDate', 'version')
    foreach ($field in $requiredConfigFields) {
        if (-not (Test-KeyExists $Configuration $field)) {
            throw "$Context must contain '$field' key."
        }
        $value = Get-Value $Configuration $field
        if ($null -ne $value -and -not ($value -is [string])) {
            throw "$Context '$field' must be a string or null."
        }
    }
    
    # OS information - must be present
    if (-not (Test-KeyExists $Configuration 'os')) {
        throw "$Context must contain 'os' key."
    }
    $os = Get-Value $Configuration 'os'
    if (-not (Test-DictionaryLike $os)) {
        throw "$Context 'os' must be a hashtable or PSCustomObject."
    }
    
    $osFields = @('architecture', 'name', 'version')
    foreach ($field in $osFields) {
        if (-not (Test-KeyExists $os $field)) {
            throw "$Context 'os' must contain '$field' key."
        }
        $value = Get-Value $os $field
        if ($null -ne $value -and -not ($value -is [string])) {
            throw "$Context 'os.$field' must be a string or null."
        }
    }
    
    # PowerShell information - must be present
    if (-not (Test-KeyExists $Configuration 'powershell')) {
        throw "$Context must contain 'powershell' key."
    }
    $ps = Get-Value $Configuration 'powershell'
    if (-not (Test-DictionaryLike $ps)) {
        throw "$Context 'powershell' must be a hashtable or PSCustomObject."
    }
    
    $psFields = @('version', 'edition')
    foreach ($field in $psFields) {
        if (-not (Test-KeyExists $ps $field)) {
            throw "$Context 'powershell' must contain '$field' key."
        }
        $value = Get-Value $ps $field
        if (-not ($value -is [string])) {
            throw "$Context 'powershell.$field' must be a string."
        }
    }
}

function Assert-CommandsValid {
    <#
    .SYNOPSIS
    Validates the commands section of a devsetup environment
    #>
    param(
        $Commands,
        [string]$Context = "commands"
    )
    
    # Normalize commands to array format
    $normalizedCommands = ConvertTo-NormalizedArray $Commands $Context
    
    # Validate array type
    if (-not ($normalizedCommands -is [array])) {
        throw "'$Context' must be an array."
    }
    
    foreach ($command in $normalizedCommands) {
        if (-not (Test-DictionaryLike $command)) {
            throw "Each command entry must be a hashtable or PSCustomObject."
        }
        
        # Validate required command fields
        if (-not (Test-KeyExists $command 'command')) {
            throw "Each command entry must contain 'command' key."
        }
        $cmdValue = Get-Value $command 'command'
        if (-not ($cmdValue -is [string]) -or [string]::IsNullOrWhiteSpace($cmdValue)) {
            throw "'command' must be a non-empty string."
        }
        
        # packageName is required for command identification/updates
        if (-not (Test-KeyExists $command 'packageName')) {
            throw "Each command entry must contain 'packageName' key."
        }
        $pkgValue = Get-Value $command 'packageName'
        if (-not ($pkgValue -is [string]) -or [string]::IsNullOrWhiteSpace($pkgValue)) {
            throw "'packageName' must be a non-empty string."
        }
        
        # params must be present
        if (-not (Test-KeyExists $command 'params')) {
            throw "Each command entry must contain 'params' key."
        }
        
        # Validate params hashtable
        $params = Get-Value $command 'params'
        
        if (-not (Test-DictionaryLike $params)) {
            throw "'params' must be a hashtable or PSCustomObject."
        }
        
        # Validate each parameter value in the hashtable
        $paramKeys = if ($params -is [hashtable] -or $params -is [System.Collections.Specialized.OrderedDictionary]) {
            $params.Keys
        } elseif ($params -is [PSCustomObject]) {
            $params.PSObject.Properties.Name
        }
        
        foreach ($key in $paramKeys) {
            $value = Get-Value $params $key
            if ($value -and -not ($value -is [string])) {
                throw "Each parameter value in 'params' hashtable must be a string or null."
            }
        }
    }
}

function Assert-PackageManagerValid {
    <#
    .SYNOPSIS
    Validates a package manager and its associated packages/modules/buckets
    #>
    param(
        [string]$ManagerName,
        $ManagerData,
        [string]$Context = "package manager"
    )
    
    if (-not (Test-DictionaryLike $ManagerData)) {
        throw "Each $Context entry must be a hashtable or PSCustomObject."
    }
    
    # Validate manager-specific structure based on canonical New-DevSetupEnvFile structure
    switch ($ManagerName) {
        'chocolatey' {
            # Chocolatey should have packages array for proper structure
            $arrayTypes = @('packages', 'modules', 'buckets')
            $foundArrays = @()
            
            foreach ($arrayType in $arrayTypes) {
                if (Test-KeyExists $ManagerData $arrayType) {
                    $foundArrays += $arrayType
                    $items = Get-Value $ManagerData $arrayType
                    Assert-PackageArrayValid -ManagerName $ManagerName -ArrayType $arrayType -Items $items
                }
            }
            
            # Ensure at least one array type is present
            if ($foundArrays.Count -eq 0) {
                throw "Manager '$ManagerName' must contain at least one of: 'packages', 'modules', or 'buckets'."
            }
        }
        'powershell' {
            # PowerShell requires scope when present
            if (-not (Test-KeyExists $ManagerData 'scope')) {
                throw "PowerShell manager must contain 'scope' key."
            }
            $scopeValue = Get-Value $ManagerData 'scope'
            if (-not ($scopeValue -is [string])) {
                throw "PowerShell manager 'scope' must be a string."
            }
            # PowerShell should have at least modules
            $arrayTypes = @('packages', 'modules', 'buckets')
            $foundArrays = @()
            
            foreach ($arrayType in $arrayTypes) {
                if (Test-KeyExists $ManagerData $arrayType) {
                    $foundArrays += $arrayType
                    $items = Get-Value $ManagerData $arrayType
                    Assert-PackageArrayValid -ManagerName $ManagerName -ArrayType $arrayType -Items $items
                }
            }
            
            # Ensure at least one array type is present
            if ($foundArrays.Count -eq 0) {
                throw "Manager '$ManagerName' must contain at least one of: 'packages', 'modules', or 'buckets'."
            }
        }
        'scoop' {
            # Scoop should have at least packages or buckets
            $arrayTypes = @('packages', 'modules', 'buckets')
            $foundArrays = @()
            
            foreach ($arrayType in $arrayTypes) {
                if (Test-KeyExists $ManagerData $arrayType) {
                    $foundArrays += $arrayType
                    $items = Get-Value $ManagerData $arrayType
                    Assert-PackageArrayValid -ManagerName $ManagerName -ArrayType $arrayType -Items $items
                }
            }
            
            # Ensure at least one array type is present
            if ($foundArrays.Count -eq 0) {
                throw "Manager '$ManagerName' must contain at least one of: 'packages', 'modules', or 'buckets'."
            }
        }
        'homebrew' {
            # Homebrew should have at least packages
            $arrayTypes = @('packages', 'modules', 'buckets')
            $foundArrays = @()
            
            foreach ($arrayType in $arrayTypes) {
                if (Test-KeyExists $ManagerData $arrayType) {
                    $foundArrays += $arrayType
                    $items = Get-Value $ManagerData $arrayType
                    Assert-PackageArrayValid -ManagerName $ManagerName -ArrayType $arrayType -Items $items
                }
            }
            
            # Ensure at least one array type is present
            if ($foundArrays.Count -eq 0) {
                throw "Manager '$ManagerName' must contain at least one of: 'packages', 'modules', or 'buckets'."
            }
        }
        default {
            # For any other managers, ensure they have at least one array type
            $arrayTypes = @('packages', 'modules', 'buckets')
            $foundArrays = @()
            
            foreach ($arrayType in $arrayTypes) {
                if (Test-KeyExists $ManagerData $arrayType) {
                    $foundArrays += $arrayType
                    $items = Get-Value $ManagerData $arrayType
                    Assert-PackageArrayValid -ManagerName $ManagerName -ArrayType $arrayType -Items $items
                }
            }
            
            # Ensure at least one array type is present
            if ($foundArrays.Count -eq 0) {
                throw "Manager '$ManagerName' must contain at least one of: 'packages', 'modules', or 'buckets'."
            }
        }
    }
}

function Assert-PackageArrayValid {
    <#
    .SYNOPSIS
    Validates an array of packages, modules, or buckets for a specific package manager
    #>
    param(
        [string]$ManagerName,
        [string]$ArrayType,
        $Items
    )
    
    # Normalize items to array format
    $normalizedItems = ConvertTo-NormalizedArray $Items "$ArrayType for manager '$ManagerName'"
    
    if (-not ($normalizedItems -is [array])) {
        throw "'$ArrayType' for manager '$ManagerName' must be an array."
    }
    
    foreach ($item in $normalizedItems) {
        Assert-PackageItemValid -ManagerName $ManagerName -ArrayType $ArrayType -Item $item
    }
}

function Assert-PackageItemValid {
    <#
    .SYNOPSIS
    Validates a single package, module, or bucket item
    #>
    param(
        [string]$ManagerName,
        [string]$ArrayType,
        $Item
    )
    
    if (-not (Test-DictionaryLike $Item)) {
        throw "Each $ArrayType entry for manager '$ManagerName' must be a hashtable or PSCustomObject."
    }
    
    # Name is always required
    if (-not (Test-KeyExists $Item 'name')) {
        throw "Each $ArrayType entry for manager '$ManagerName' must contain 'name' key."
    }
    $nameValue = Get-Value $Item 'name'
    if (-not ($nameValue -is [string]) -or [string]::IsNullOrWhiteSpace($nameValue)) {
        throw "'name' for $ArrayType entry must be a non-empty string."
    }
    
    # Manager and array type specific validation
    switch ("$ManagerName-$ArrayType") {
        'powershell-modules' {
            Assert-PowerShellModuleValid $Item
        }
        'scoop-packages' {
            Assert-ScoopPackageValid $Item
        }
        default {
            if ($ArrayType -eq 'packages') {
                Assert-GenericPackageValid $Item $ManagerName
            } elseif ($ArrayType -eq 'buckets') {
                Assert-BucketValid $Item $ManagerName
            }
        }
    }
    
    # Common version validation
    Assert-VersionFieldsValid $Item $ArrayType
}

function Assert-PowerShellModuleValid {
    param($Item)
    
    # PowerShell modules require specific fields
    $requiredFields = @('version', 'minimumVersion', 'scope')
    foreach ($field in $requiredFields) {
        if (-not (Test-KeyExists $Item $field)) {
            throw "PowerShell module must contain '$field' key."
        }
        $fieldValue = Get-Value $Item $field
        if (-not ($fieldValue -is [string])) {
            throw "PowerShell module '$field' must be a string."
        }
    }
}

function Assert-ScoopPackageValid {
    param($Item)
    
    # Scoop packages require bucket field
    if (-not (Test-KeyExists $Item 'bucket')) {
        throw "Scoop package must contain 'bucket' key."
    }
    $bucketValue = Get-Value $Item 'bucket'
    if (-not ($bucketValue -is [string])) {
        throw "Scoop package 'bucket' must be a string."
    }
}

function Assert-GenericPackageValid {
    param($Item, $ManagerName)
    
    # All packages require version field
    if (-not (Test-KeyExists $Item 'version')) {
        throw "$ManagerName package must contain 'version' key."
    }
    
    $versionValue = Get-Value $Item 'version'
    # Handle null version (treat as empty string)
    if ($null -eq $versionValue) {
        $versionValue = ""
    }
    if (-not ($versionValue -is [string])) {
        throw "$ManagerName package 'version' must be a string."
    }
    
    # minimumVersion is optional for packages
    if (Test-KeyExists $Item 'minimumVersion') {
        $minVersionValue = Get-Value $Item 'minimumVersion'
        # Handle null minimumVersion (treat as empty string)
        if ($null -eq $minVersionValue) {
            $minVersionValue = ""
        }
        if (-not ($minVersionValue -is [string])) {
            throw "$ManagerName package 'minimumVersion' must be a string."
        }
    }
}

function Assert-BucketValid {
    param($Item, $ManagerName)
    
    # Buckets require source field
    if (-not (Test-KeyExists $Item 'source')) {
        throw "$ManagerName bucket must contain 'source' key."
    }
    $sourceValue = Get-Value $Item 'source'
    if (-not ($sourceValue -is [string])) {
        throw "$ManagerName bucket 'source' must be a string."
    }
}

function Assert-VersionFieldsValid {
    param($Item, $Context)
    
    $hasVersion = Test-KeyExists $Item 'version'
    $hasMinimumVersion = Test-KeyExists $Item 'minimumVersion'
    
    if ($hasVersion -and $hasMinimumVersion) {
        $versionValue = Get-Value $Item 'version'
        $minVersionValue = Get-Value $Item 'minimumVersion'
        
        # Handle null values
        if ($null -eq $versionValue) { $versionValue = "" }
        if ($null -eq $minVersionValue) { $minVersionValue = "" }
        
        # Both must be strings
        if ($versionValue -and -not ($versionValue -is [string])) {
            throw "'version' for $Context entry must be a string."
        }
        if ($minVersionValue -and -not ($minVersionValue -is [string])) {
            throw "'minimumVersion' for $Context entry must be a string."
        }
        
        # Cannot have both with non-empty values
        if (-not [string]::IsNullOrWhiteSpace($versionValue) -and -not [string]::IsNullOrWhiteSpace($minVersionValue)) {
            throw "Cannot specify both 'version' and 'minimumVersion' with values for $Context entry. Use only one."
        }
    }
}

function Assert-DependenciesValid {
    <#
    .SYNOPSIS
    Validates the dependencies section of a devsetup environment
    #>
    param(
        $Dependencies,
        [string]$Context = "dependencies"
    )
    
    if (-not (Test-DictionaryLike $Dependencies)) {
        throw "'$Context' must be a hashtable or PSCustomObject."
    }
    
    # Get all manager names - handle hashtable, OrderedDictionary and PSCustomObject
    $managerNames = if ($Dependencies -is [hashtable] -or $Dependencies -is [System.Collections.Specialized.OrderedDictionary]) {
        $Dependencies.Keys
    } elseif ($Dependencies -is [PSCustomObject]) {
        $Dependencies.PSObject.Properties.Name
    }
    
    foreach ($manager in $managerNames) {
        $managerData = Get-Value $Dependencies $manager
        Assert-PackageManagerValid -ManagerName $manager -ManagerData $managerData
    }
}

Function Assert-DevSetupEnvValid {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        $EnvData  # Accept both hashtable and PSCustomObject
    )

    # Validate root structure
    if (-not (Test-DictionaryLike $EnvData)) {
        throw "Environment data must be a hashtable or PSCustomObject."
    }
    
    if (-not (Test-KeyExists $EnvData 'devsetup')) {
        throw "Environment data must contain 'devsetup' key."
    }
    
    $devsetup = Get-Value $EnvData 'devsetup'
    if (-not (Test-DictionaryLike $devsetup)) {
        throw "'devsetup' must be a hashtable or PSCustomObject."
    }
    
    # Validate required top-level sections
    $requiredSections = @('configuration', 'dependencies', 'commands')
    foreach ($section in $requiredSections) {
        if (-not (Test-KeyExists $devsetup $section)) {
            throw "Environment data 'devsetup' section must contain '$section' key."
        }
    }
    
    # Validate each section using specialized functions
    $config = Get-Value $devsetup 'configuration'
    Assert-ConfigurationValid $config
    
    $dependencies = Get-Value $devsetup 'dependencies'
    Assert-DependenciesValid $dependencies
    
    $commands = Get-Value $devsetup 'commands'
    Assert-CommandsValid $commands

    return $true
}