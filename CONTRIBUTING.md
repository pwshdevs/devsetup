# Contributing to DevSetup

Thank you for your interest in contributing to DevSetup! This document provides guidelines and information for contributors.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

By participating in this project, you are expected to uphold our code of conduct. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites
- **PowerShell 5.1+**
- **Pester 5.0+** for running tests
- **Git** for version control
- A code editor with PowerShell support (recommended: VS Code with PowerShell extension)

### First Time Setup
1. Fork the repository on GitHub
2. Clone your fork locally:
   ```powershell
   git clone https://github.com/pwshdevs/devsetup.git
   cd devsetup
   ```
3. Add the upstream repository:
   ```powershell
   git remote add upstream https://github.com/pwshdevs/devsetup.git
   ```
4. Install the module in development mode:
   ```powershell
   .\install.ps1 -self
   ```

## Development Setup

### Repository Structure
```
devsetup/
├── DevSetup/                    # Main module directory
│   ├── DevSetup.psd1           # Module manifest
│   ├── DevSetup.psm1           # Module script
│   ├── Private/                # Private functions
│   │   ├── Commands/           # Main command implementations
│   │   ├── Providers/          # Provider-specific functions
│   │   │   ├── Chocolatey/     # Chocolatey provider
│   │   │   ├── Scoop/          # Scoop provider
│   │   │   └── ...
│   │   └── Utils/              # Utility functions
│   └── Public/                 # Public functions (module exports)
├── docs/                       # Documentation
├── install.ps1                 # Installation script
├── runTests.ps1               # Test runner
└── runSecurity.ps1            # Security checks
```

### Running Tests
```powershell
# Run all tests
.\runTests.ps1

# Run tests for a specific file
Invoke-Pester -Path "DevSetup\Private\Providers\Scoop\*.Tests.ps1"

# Run tests with coverage
Invoke-Pester -Path "DevSetup\Private\Providers\Scoop\*.Tests.ps1" -CodeCoverage "DevSetup\Private\Providers\Scoop\*.ps1"
```

### Security Analysis
```powershell
# Run security analysis
.\runSecurity.ps1
```

## Making Changes

### Branch Naming
- **Feature branches**: `feature/description-of-feature`
- **Bug fixes**: `fix/description-of-fix`
- **Documentation**: `docs/description-of-change`
- **Tests**: `test/description-of-test-change`

### Commit Messages
Use clear, descriptive commit messages following conventional commits:
- `feat: add new scoop package provider`
- `fix: resolve chocolatey installation issue`
- `docs: update installation instructions`
- `test: add comprehensive tests for Install-ScoopPackage`
- `refactor: improve error handling in Uninstall-ScoopBucket`

## Testing

### Test Requirements
- **All new functions MUST have comprehensive tests**
- **Aim for 100% code coverage** on new code
- **Follow existing test patterns** in the codebase
- **Test both success and failure scenarios**
- **Include edge cases and error handling**

### Test Structure
```powershell
BeforeAll {
    # Dot-source the function and dependencies
    . $PSScriptRoot\YourFunction.ps1
    . $PSScriptRoot\..\..\Utils\Write-StatusMessage.ps1
    
    # Global mocks if needed
    Mock Write-StatusMessage { }
}

Describe "YourFunction" {
    BeforeEach {
        # Reset state before each test
        $global:LASTEXITCODE = 0
    }
    
    Context "When normal operation succeeds" {
        It "Should return expected result" {
            # Test implementation
        }
    }
    
    Context "When error conditions occur" {
        It "Should handle errors gracefully" {
            # Test error handling
        }
    }
}
```

### Test Patterns
- **Use PSCustomObject for YAML data** to match `Assert-DevSetupEnvValid` requirements
- **Mock external dependencies** (commands, file operations, etc.)
- **Test WhatIf/ShouldProcess functionality** for functions that support it
- **Verify parameter validation** and edge cases
- **Test exception handling** with proper error logging

## Coding Standards

### PowerShell Best Practices
- **Use approved verbs** for function names (`Get-`, `Set-`, `Install-`, etc.)
- **Follow PascalCase** for function names and parameters
- **Use full parameter names** in scripts (avoid aliases)
- **Include comprehensive help documentation** with examples
- **Use `[CmdletBinding()]`** for advanced functions
- **Implement proper error handling** with try/catch blocks
- **Support WhatIf/Confirm** for functions that make changes

### Function Structure
```powershell
<#
.SYNOPSIS
    Brief description of what the function does.

.DESCRIPTION
    Detailed description with comprehensive information.

.PARAMETER ParameterName
    Description of the parameter.

.OUTPUTS
    [System.Type]
    Description of what the function returns.

.EXAMPLE
    FunctionName -Parameter "value"
    
    Description of what this example does.

.NOTES
    Additional implementation notes, requirements, or caveats.
#>
Function FunctionName {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterName
    )
    
    # Implementation with proper error handling
    try {
        if ($PSCmdlet.ShouldProcess($target, $operation)) {
            # Perform the operation
        } else {
            Write-StatusMessage "Skipping operation due to ShouldProcess" -Verbosity Debug
            return $true
        }
    } catch {
        Write-StatusMessage "Error message: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}
```

### Error Handling Standards
- **Use try/catch blocks** for operations that may fail
- **Log both error messages and stack traces** using `Write-StatusMessage`
- **Return boolean values** for success/failure indication
- **Continue processing** when possible (don't fail fast unless critical)

### Provider Development
When adding new providers:
1. **Follow existing provider patterns** (see Scoop/Chocolatey examples)
2. **Implement core functions**: Install, Uninstall, Test-Installed, Find-Provider
3. **Support batch operations** with comprehensive progress reporting
4. **Include cache management** if applicable
5. **Handle both simple and complex object formats** in configurations

## Pull Request Process

### Before Submitting
1. **Ensure all tests pass**: `.\runTests.ps1`
2. **Run security analysis**: `.\runSecurity.ps1`
3. **Update documentation** if needed
4. **Add tests for new functionality**
5. **Follow coding standards**

### PR Description Template
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] Added tests for new functionality
- [ ] Code coverage maintained/improved

## Screenshots (if applicable)

## Additional Notes
Any additional information or context.
```

### Review Process
1. **Automated checks** must pass (tests, security analysis)
2. **Code review** by at least one maintainer
3. **Documentation review** if docs are changed
4. **Final approval** and merge by maintainer

## Reporting Issues

### Bug Reports
When reporting bugs, please include:
- **PowerShell version** (`$PSVersionTable`)
- **Operating system** and version
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Error messages** or stack traces
- **Relevant configuration** (sanitized)

### Feature Requests
For new features:
- **Describe the use case** and problem being solved
- **Provide examples** of how it would be used
- **Consider implementation complexity** and maintenance burden
- **Check existing issues** to avoid duplicates

### Issue Labels
- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Improvements or additions to documentation
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention is needed
- `question`: Further information is requested

## Development Tips

### Debugging
- Use `Write-StatusMessage` with `-Verbosity Debug` for debugging output
- Test with `-WhatIf` parameter to see what would happen without making changes
- Use `Get-DevSetupEnvList` to see available environments for testing

### Testing Specific Providers
```powershell
# Test Scoop provider functions
Invoke-Pester -Path "DevSetup\Private\Providers\Scoop\*.Tests.ps1" -Output Detailed

# Test with coverage
Invoke-Pester -Path "DevSetup\Private\Providers\Scoop\Install-ScoopPackage.Tests.ps1" -CodeCoverage "DevSetup\Private\Providers\Scoop\Install-ScoopPackage.ps1"
```

### Working with YAML Configurations
- Use `Assert-DevSetupEnvValid` structure for test data
- Create `PSCustomObject` structures rather than hashtables
- Test both simple strings and complex objects in configurations

## Questions?

If you have questions that aren't covered in this guide:
- Check existing [Issues](https://github.com/pwshdevs/devsetup/issues)
- Start a [Discussion](https://github.com/pwshdevs/devsetup/discussions)
- Review the [Documentation](./DevSetup/docs/)

Thank you for contributing to DevSetup! 🎉