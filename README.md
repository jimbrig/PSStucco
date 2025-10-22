# PSStucco <img src="./media/trowel.png" alt="Trowel"  height="8%" width="8%" style="float:right" align="right">

> [!IMPORTANT]
> This is a rebuild of the [Stucco](https://github.com/devblackops/Stucco) Module with some various tweaks and bugfixes for personal use.
> Feel free to use also. You can view the differences and details by looking at [the commit changes](https://github.com/devblackops/Stucco/compare/main...jimbrig:PSStucco:main) and the [issues from devblackops/Stucco](https://github.com/devblackops/Stucco/issues).

> [!NOTE]
> **🚀 Now Modernized for PowerShell 7+ with Microsoft.PowerShell.PSResourceGet!**
>
> This version has been completely modernized to leverage PowerShell 7.0+ and the new Microsoft.PowerShell.PSResourceGet module for enhanced performance, reliability, and security.

## Contents

- [Badges](#badges)
- [Overview](#overview)
- [Features](#features)
- [Modern Build System](#modern-build-system)
- [Installation](#installation)
- [Usage](#usage)
- [Contribution](#contribution)

***

## Badges

| Publish |  PS Gallery | License |
|----------------|-------------|---------|
[![Publish](https://github.com/jimbrig/PSStucco/actions/workflows/publish.yaml/badge.svg)](https://github.com/jimbrig/PSStucco/actions/workflows/publish.yaml) | [![PowerShell Gallery][psgallery-badge]][psgallery] | [![License][license-badge]][license]


## Overview

> [!TIP]
> (PS)Stucco is an **opinionated** [Plaster](https://github.com/PowerShellOrg/Plaster) template for building high-quality [PowerShell](https://github.com/PowerShell/PowerShell) modules.
> This template produces PowerShell projects according to a structure that I and many others in the PowerShell community use.
> Apart from the PowerShell module itself, this template creates project scaffolding that enables effective collaboration with the community.

> [!NOTE]
> The repository now uses a modern source layout: `src/PSStucco` for the module source and `tests/` for tests. Generated modules from this template will follow `src/{ModuleName}` as well.


## Features

- **Modern PowerShell 7+ Support** with Microsoft.PowerShell.PSResourceGet
- MIT, Apache, or Unlicense licensing options
- Changelog following [Keep a Changelog](http://keepachangelog.com/) guidelines with [Semantic Versioning](http://semver.org/)
- Optional [Code of Conduct](http://contributor-covenant.org)
- Optional [Read The Docs](https://readthedocs.org/) support for online documentation using [Mkdocs](https://www.mkdocs.org/)
- Optional [PlatyPS](https://github.com/PowerShell/platyPS) support for markdown-based help documentation
- Modern dependency management using Microsoft.PowerShell.PSResourceGet
- [psake](https://github.com/psake/psake) and [Invoke-Build](https://github.com/nightroman/Invoke-Build) support for build automation
- Enhanced CI/CD with GitHub Actions, Azure Pipelines, and GitLab CI
- Advanced DevContainer and VSCode support with 20+ modern extensions
- Comprehensive security scanning and code quality tools
- Pre-commit hooks and EditorConfig for consistent development

## Modern Build System

PSStucco now includes a modernized build system with these enhancements:

### 🚀 Enhanced Bootstrap Process
```powershell
# Modern bootstrap with PSResourceGet
./build.ps1 -Bootstrap -Force -Prerelease

# Modern dependency management
./Manage-Dependencies.ps1 -Action Install -Force
./Manage-Dependencies.ps1 -Action Update -Prerelease
./Manage-Dependencies.ps1 -Action Audit
```

### 🔧 Key Improvements
- **Performance**: Up to 2x faster package operations
- **Reliability**: Better dependency resolution and error handling
- **Security**: Enhanced security features and auditing

- **Modern UI**: Colored output and progress indicators

### 📦 Requirements Management
Supports both modern and traditional package specifications:
```powershell
@{
    'Microsoft.PowerShell.PSResourceGet' = @{ Version = 'latest' }
    'Pester' = @{ Version = '5.6.1'; Prerelease = $false }
    'PSScriptAnalyzer' = '1.22.0'  # Simple version
}
```

## Installation

Install from the [PowerShell Gallery]():

```powershell
Install-PSResource PSStucco
```

## Usage

```powershell
$template = Get-PlasterTemplate -IncludeInstalledModules | Where-Object TemplatePath -Match 'Stucco'

Invoke-Plaster -TemplatePath $template.TemplatePath
```

## Contribution

The goal of this project is help create common patterns for PowerShell module development.
Additional features or capabilities that benefit the community are welcome.

[psgallery-badge]: https://img.shields.io/powershellgallery/dt/stucco.svg
[psgallery]: https://www.powershellgallery.com/packages/PSStucco
[license-badge]: https://img.shields.io/github/license/jimbrig/stucco.svg
[license]: https://www.powershellgallery.com/packages/psstucco
