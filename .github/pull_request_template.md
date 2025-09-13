---
name: Pull Request
about: Submit changes to the DevSetup project
title: ''
labels: ''
assignees: ''
---

## Summary

<!-- Provide a brief description of what this PR accomplishes -->

## Type of Change

<!-- Check all that apply -->
- [ ] 🐛 **Bug fix** (non-breaking change which fixes an issue)
- [ ] ✨ **New feature** (non-breaking change which adds functionality)
- [ ] 💥 **Breaking change** (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 **Documentation** (changes to documentation only)
- [ ] 🧪 **Tests** (adding missing tests or correcting existing tests)
- [ ] ♻️ **Refactor** (code changes that neither fix a bug nor add a feature)
- [ ] 🎨 **Style** (formatting, missing semi-colons, etc; no production code change)
- [ ] ⚡ **Performance** (code changes that improve performance)
- [ ] 🔧 **Chore** (updating grunt tasks, build processes, etc; no production code change)

## Changes Made

<!-- Describe the changes in detail. Use bullet points for multiple changes -->
- 
- 
- 

## Provider/Component Affected

<!-- Check all that apply -->
- [ ] 📦 **Core Commands** (Install-DevSetupEnv, Export-DevSetupEnv, etc.)
- [ ] 🍫 **Chocolatey Provider** (Chocolatey package management)
- [ ] 🥄 **Scoop Provider** (Scoop package management)
- [ ] 🍺 **Homebrew Provider** (Homebrew package management)
- [ ] 💎 **PowerShell Provider** (PowerShell module management)
- [ ] 🏗️ **Core Dependencies** (Git repositories, Nuget packages)
- [ ] 🔧 **Utilities** (Helper functions, logging, validation)
- [ ] 📋 **3rd Party Integrations** (Visual Studio, VS Code)
- [ ] 📖 **Documentation** (README, CONTRIBUTING, etc.)
- [ ] ⚙️ **Build/CI** (GitHub Actions, scripts)

## Testing

### Test Coverage
- [ ] ✅ **All existing tests pass** (`.\runTests.ps1`)
- [ ] ✅ **New tests added** for new functionality
- [ ] ✅ **Test coverage maintained/improved** (aim for 100% on new code)
- [ ] ✅ **Security analysis passes** (`.\runSecurity.ps1`)

### Test Types Added/Modified
<!-- Check all that apply -->
- [ ] 🔧 **Unit Tests** (individual function testing)
- [ ] 🔄 **Integration Tests** (cross-component testing)
- [ ] 🚨 **Error Handling Tests** (exception scenarios)
- [ ] 🎭 **Mock/Stub Tests** (external dependency mocking)
- [ ] 👀 **WhatIf/ShouldProcess Tests** (dry-run functionality)
- [ ] 🔍 **Edge Case Tests** (boundary conditions, invalid inputs)

### Manual Testing
<!-- Describe any manual testing performed -->
- [ ] ✅ **Tested on Windows PowerShell 5.1**
- [ ] ✅ **Tested on PowerShell 7.x**
- [ ] ✅ **Tested with `-WhatIf` parameter**
- [ ] ✅ **Tested error scenarios**
- [ ] ✅ **Tested with real environment files**

**Manual testing details:**
<!-- Describe specific manual testing scenarios -->

## Code Quality

### PowerShell Best Practices
- [ ] ✅ **Uses approved verbs** (Get-, Set-, Install-, etc.)
- [ ] ✅ **Follows PascalCase** for functions and parameters
- [ ] ✅ **Includes comprehensive help documentation**
- [ ] ✅ **Uses `[CmdletBinding()]`** for advanced functions
- [ ] ✅ **Implements proper error handling** (try/catch with logging)
- [ ] ✅ **Supports WhatIf/Confirm** (where applicable)
- [ ] ✅ **Uses `Write-StatusMessage`** for consistent logging

### Security Considerations
- [ ] ✅ **Input validation implemented**
- [ ] ✅ **No hardcoded secrets or credentials**
- [ ] ✅ **Secure error messages** (no sensitive info exposure)
- [ ] ✅ **Minimal required permissions**
- [ ] ✅ **Follows security best practices** from SECURITY.md

## Breaking Changes

<!-- If this is a breaking change, describe what breaks and the migration path -->
- **What breaks:** 
- **Migration path:** 
- **Deprecation notices:** 

## Related Issues

<!-- Link to GitHub issues this PR addresses -->
Fixes #(issue number)
Closes #(issue number)
Relates to #(issue number)

## Screenshots/Output

<!-- If applicable, add screenshots or command output to help explain your changes -->

### Before
```powershell
# Show current behavior
```

### After
```powershell
# Show new behavior
```

## Checklist

### Code Requirements
- [ ] ✅ **Code follows the project's coding standards** (see CONTRIBUTING.md)
- [ ] ✅ **Self-review completed** (checked my own PR for issues)
- [ ] ✅ **Code is properly commented** (especially complex logic)
- [ ] ✅ **No debug code or console.log statements** left in
- [ ] ✅ **Function/parameter names are descriptive**

### Documentation Requirements
- [ ] ✅ **Help documentation updated** (if adding/changing functions)
- [ ] ✅ **CONTRIBUTING.md updated** (if changing development process)
- [ ] ✅ **README.md updated** (if changing user-facing features)
- [ ] ✅ **Examples provided** in help documentation

### Testing Requirements
- [ ] ✅ **All tests pass locally**
- [ ] ✅ **New tests follow existing patterns** (BeforeAll/BeforeEach structure)
- [ ] ✅ **PSCustomObject used for YAML test data** (matches Assert-DevSetupEnvValid)
- [ ] ✅ **Proper mocking of external dependencies**
- [ ] ✅ **Exception handling tests included**

### Provider-Specific (if applicable)
- [ ] ✅ **Follows provider patterns** (Install/Uninstall/Test functions)
- [ ] ✅ **Supports batch operations** with progress reporting
- [ ] ✅ **Includes cache management** (if applicable)
- [ ] ✅ **Handles simple and complex object formats**
- [ ] ✅ **Proper parameter splatting** for sub-functions

## Additional Notes

<!-- Any additional information that reviewers should know -->

## Review Focus Areas

<!-- Guide reviewers to specific areas that need attention -->
- **Security implications:** 
- **Performance impact:** 
- **Breaking change validation:** 
- **Test coverage gaps:** 
- **Documentation clarity:** 

---

### Reviewer Checklist

<!-- For reviewers to complete -->
- [ ] 🔍 **Code review completed**
- [ ] 🧪 **Test review completed**
- [ ] 📚 **Documentation review completed**
- [ ] 🔒 **Security review completed**
- [ ] ✅ **Approved for merge**

/cc @pwshdevs <!-- Notify maintainers -->