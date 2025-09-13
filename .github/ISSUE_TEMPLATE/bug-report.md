---
name: 🐛 Bug Report
about: Create a report to help us improve DevSetup
title: '[BUG] '
labels: ['bug', 'needs-triage']
assignees: ''
---

## Bug Description

**Brief Summary**
<!-- A clear and concise description of what the bug is -->

**Expected Behavior**
<!-- What you expected to happen -->

**Actual Behavior**
<!-- What actually happened -->

## Environment Information

**PowerShell Version**
<!-- Paste the output of $PSVersionTable -->
```powershell

```

**DevSetup Version**
<!-- Paste the output of Get-Module DevSetup or the version you're using -->
```powershell

```

**Operating System**
<!-- e.g., Windows 11, Windows 10, macOS, Linux -->
- OS: 
- Version: 
- Architecture: [x64/x86/ARM]

**Package Manager Versions** (if applicable)
<!-- Check versions of relevant package managers -->
- [ ] Chocolatey: `choco --version` → 
- [ ] Scoop: `scoop --version` → 
- [ ] PowerShell Gallery: Available
- [ ] Homebrew: `brew --version` → 

## Reproduction Steps

**Steps to Reproduce**
1. 
2. 
3. 
4. 

**DevSetup Command Used**
```powershell
# Paste the exact command that caused the issue
```

**Environment File** (if applicable)
<!-- Paste relevant parts of your .devsetup file (remove any sensitive info) -->
```yaml

```

## Error Details

**Error Messages**
<!-- Paste any error messages, warnings, or unexpected output -->
```
Paste error output here
```

**Stack Traces** (if available)
<!-- Include full stack traces if shown -->
```
Paste stack trace here
```

**Log Output** (if available)
<!-- Include relevant log output with -Verbose or Debug flags -->
```
Paste log output here
```

## Provider-Specific Information

**Which provider is affected?** (check all that apply)
- [ ] 🍫 Chocolatey Provider
- [ ] 🥄 Scoop Provider  
- [ ] 🍺 Homebrew Provider
- [ ] 💎 PowerShell Module Provider
- [ ] 🏗️ Core Dependencies (Git, Nuget)
- [ ] 📋 3rd Party (Visual Studio, VS Code)
- [ ] 📦 Core Commands
- [ ] 🔧 Utilities/Helper functions

**Specific Package/Component** (if applicable)
<!-- Name of specific package or component causing issues -->

## Additional Context

**Screenshots**
<!-- If applicable, add screenshots to help explain the problem -->

**Configuration Details**
<!-- Any special configuration, network setup, or corporate environment details -->

**Workarounds Attempted**
<!-- What have you tried to fix or work around this issue? -->
- [ ] Restarted PowerShell session
- [ ] Ran as Administrator
- [ ] Used `-DryRUn` to test
- [ ] Checked package manager directly
- [ ] Cleared caches
- [ ] Other: 

**Related Issues**
<!-- Link any related issues or discussions -->

## Impact Assessment

**Frequency**
- [ ] Happens every time
- [ ] Happens sometimes
- [ ] Happened once
- [ ] Only in specific conditions

**Severity**
- [ ] 🔥 Critical - Blocks all functionality
- [ ] 🚨 High - Blocks major functionality  
- [ ] ⚠️ Medium - Impacts some functionality
- [ ] 📝 Low - Minor issue or cosmetic

**Workaround Available**
- [ ] Yes - I can work around this issue
- [ ] No - This completely blocks my progress

---

**Checklist before submitting:**
- [ ] ✅ I have searched existing issues for duplicates
- [ ] ✅ I have provided all requested environment information
- [ ] ✅ I have included clear reproduction steps
- [ ] ✅ I have removed or obfuscated any sensitive information
- [ ] ✅ I have tested with the latest version of DevSetup