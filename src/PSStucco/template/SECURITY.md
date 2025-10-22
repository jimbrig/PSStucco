# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it by emailing [security@example.com](mailto:security@example.com).

Please include the following information:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt of your vulnerability report within 48 hours and send a more detailed response within 72 hours indicating the next steps in handling your report.

## Security Measures

This project implements the following security measures:

- **Dependency Scanning**: Automated dependency vulnerability scanning via Dependabot
- **Code Analysis**: Static code analysis using PSScriptAnalyzer with security rules
- **SARIF Integration**: Security findings are exported in SARIF format for GitHub Security tab
- **Signed Releases**: All releases are signed with a trusted certificate
- **Supply Chain Security**: Dependencies are pinned and regularly updated

## Security Best Practices

When contributing to this project:

1. Never commit secrets, passwords, or sensitive information
2. Use secure coding practices for PowerShell
3. Follow the principle of least privilege
4. Validate all inputs
5. Use approved cryptographic libraries
6. Keep dependencies up to date

## Disclosure Policy

We follow responsible disclosure practices. Security vulnerabilities will be disclosed publicly only after:

1. The issue has been fixed
2. Affected users have been notified
3. Sufficient time has passed for updates to be deployed

Thank you for helping keep this project secure!
