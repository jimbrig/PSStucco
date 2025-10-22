#Requires -Version 7.0

<#
.SYNOPSIS
    Modern PowerShell dependency management helper using PSResourceGet

.DESCRIPTION
    This script provides modern dependency management capabilities for PowerShell projects,
    leveraging Microsoft.PowerShell.PSResourceGet for enhanced performance and reliability.

.PARAMETER Action
    The action to perform: Install, Update, List, or Clean

.PARAMETER Force
    Force reinstallation of modules

.PARAMETER Prerelease
    Include prerelease versions

.PARAMETER Scope
    Installation scope: CurrentUser or AllUsers

.PARAMETER RequirementsFile
    Path to requirements.psd1 file

.EXAMPLE
    .\Manage-Dependencies.ps1 -Action Install

.EXAMPLE
    .\Manage-Dependencies.ps1 -Action Update -Force -Prerelease

.EXAMPLE
    .\Manage-Dependencies.ps1 -Action List
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Install', 'Update', 'List', 'Clean', 'Audit')]
    [string]$Action,

    [switch]$Force,
    [switch]$Prerelease,

    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',

    [string]$RequirementsFile = './requirements.psd1'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-ModernOutput {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )

    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Info' { 'Cyan' }
        default { 'White' }
    }

    $emoji = switch ($Level) {
        'Success' { '✅' }
        'Warning' { '⚠️' }
        'Error' { '❌' }
        'Info' { 'ℹ️' }
        default { '📋' }
    }

    Write-Host "$emoji $Message" -ForegroundColor $color
}

function Initialize-PSResourceGet {
    Write-ModernOutput "Initializing Microsoft.PowerShell.PSResourceGet..." -Level Info

    try {
        # Check if PSResourceGet is available
        $psResourceGet = Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable |
            Sort-Object Version -Descending | Select-Object -First 1

        if (-not $psResourceGet) {
            Write-ModernOutput "Installing Microsoft.PowerShell.PSResourceGet..." -Level Info
            Install-Module Microsoft.PowerShell.PSResourceGet -Force -Scope $Scope -AllowClobber
        }

        Import-Module Microsoft.PowerShell.PSResourceGet -Force

        # Ensure PSGallery is registered and trusted
        $psGallery = Get-PSResourceRepository -Name PSGallery -ErrorAction SilentlyContinue
        if (-not $psGallery) {
            Write-ModernOutput "Registering PSGallery repository..." -Level Info
            Register-PSResourceRepository -PSGallery
        }

        if ($psGallery -and -not $psGallery.Trusted) {
            Write-ModernOutput "Setting PSGallery as trusted..." -Level Info
            Set-PSResourceRepository -Name PSGallery -Trusted
        }

        Write-ModernOutput "PSResourceGet initialized successfully" -Level Success
        return $true
    }
    catch {
        Write-ModernOutput "Failed to initialize PSResourceGet: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-RequiredModules {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-ModernOutput "Requirements file not found: $Path" -Level Warning
        return @{}
    }

    try {
        $requirements = Import-PowerShellDataFile -Path $Path
        $modules = @{}

        foreach ($key in $requirements.Keys) {
            if ($key -eq 'PSDependOptions') { continue }
            $modules[$key] = $requirements[$key]
        }

        Write-ModernOutput "Loaded $($modules.Count) module requirements" -Level Info
        return $modules
    }
    catch {
        Write-ModernOutput "Failed to load requirements: $($_.Exception.Message)" -Level Error
        return @{}
    }
}

function Install-ModuleWithFallback {
    param(
        [string]$Name,
        [hashtable]$ModuleInfo,
        [string]$Scope,
        [switch]$Force,
        [switch]$Prerelease
    )

    $installParams = @{
        Name = $Name
        Scope = $Scope
        TrustRepository = $true
    }

    if ($Force) { $installParams.Reinstall = $true }

    # Handle version specification
    if ($ModuleInfo -is [hashtable] -and $ModuleInfo.Version -and $ModuleInfo.Version -ne 'latest') {
        $installParams.Version = $ModuleInfo.Version
    }

    # Handle prerelease
    if ($Prerelease -or ($ModuleInfo -is [hashtable] -and $ModuleInfo.Prerelease)) {
        $installParams.Prerelease = $true
    }

    try {
        # Install using PSResourceGet only
        Write-ModernOutput "Installing $Name using PSResourceGet..." -Level Info
        Install-PSResource @installParams
        Write-ModernOutput "Successfully installed: $Name" -Level Success
        return $true
    } catch {
        Write-ModernOutput "Failed to install $Name via PSResourceGet: $($_.Exception.Message)" -Level Error
        return $false
    }
}

switch ($Action) {
    'Install' {
        Write-ModernOutput "🚀 Starting dependency installation..." -Level Info

        if (-not (Initialize-PSResourceGet)) {
            exit 1
        }

        $modules = Get-RequiredModules -Path $RequirementsFile
        if ($modules.Count -eq 0) {
            Write-ModernOutput "No modules to install" -Level Warning
            exit 0
        }

        $successCount = 0
        $failureCount = 0

        foreach ($moduleName in $modules.Keys) {
            $moduleInfo = $modules[$moduleName]

            # Check if already installed
            if (-not $Force) {
                $installed = Get-PSResource -Name $moduleName -ErrorAction SilentlyContinue
                if ($installed) {
                    Write-ModernOutput "$moduleName is already installed (v$($installed.Version))" -Level Info
                    $successCount++
                    continue
                }
            }

            $result = Install-ModuleWithFallback -Name $moduleName -ModuleInfo $moduleInfo -Scope $Scope -Force:$Force -Prerelease:$Prerelease
            if ($result) {
                $successCount++
            } else {
                $failureCount++
            }
        }

        Write-ModernOutput "Installation complete: $successCount successful, $failureCount failed" -Level $(if ($failureCount -eq 0) { 'Success' } else { 'Warning' })

        if ($failureCount -gt 0) {
            exit 1
        }
    }

    'Update' {
        Write-ModernOutput "🔄 Updating all modules..." -Level Info

        if (-not (Initialize-PSResourceGet)) {
            exit 1
        }

        try {
            $modules = Get-PSResource | Where-Object Repository -eq 'PSGallery'
            foreach ($module in $modules) {
                Write-ModernOutput "Updating $($module.Name)..." -Level Info
                Update-PSResource -Name $module.Name -Force:$Force -Prerelease:$Prerelease
            }
            Write-ModernOutput "All modules updated successfully" -Level Success
        }
        catch {
            Write-ModernOutput "Update failed: $($_.Exception.Message)" -Level Error
            exit 1
        }
    }

    'List' {
        Write-ModernOutput "📋 Listing installed modules..." -Level Info

        try {
            $modules = Get-PSResource | Sort-Object Name
            $modules | Format-Table Name, Version, Repository, Author -AutoSize
            Write-ModernOutput "Found $($modules.Count) installed modules" -Level Info
        }
        catch {
            Write-ModernOutput "Failed to list modules: $($_.Exception.Message)" -Level Error
            exit 1
        }
    }

    'Clean' {
        Write-ModernOutput "🧹 Cleaning up old module versions..." -Level Info

        try {
            $modules = Get-PSResource | Group-Object Name | Where-Object Count -gt 1
            foreach ($moduleGroup in $modules) {
                $sortedVersions = $moduleGroup.Group | Sort-Object Version -Descending
                $latestVersion = $sortedVersions[0]
                $oldVersions = $sortedVersions[1..$($sortedVersions.Count - 1)]

                foreach ($oldModule in $oldVersions) {
                    Write-ModernOutput "Removing old version: $($oldModule.Name) v$($oldModule.Version)" -Level Info
                    Uninstall-PSResource -Name $oldModule.Name -Version $oldModule.Version
                }
            }
            Write-ModernOutput "Cleanup completed" -Level Success
        }
        catch {
            Write-ModernOutput "Cleanup failed: $($_.Exception.Message)" -Level Error
            exit 1
        }
    }

    'Audit' {
        Write-ModernOutput "🔍 Auditing module security..." -Level Info

        try {
            $modules = Get-PSResource
            $issues = @()

            foreach ($module in $modules) {
                # Check for known vulnerable versions (this would need a vulnerability database)
                # For now, just check for very old versions
                if ($module.PublishedDate -lt (Get-Date).AddYears(-2)) {
                    $issues += "⚠️ $($module.Name) v$($module.Version) is very old (published $($module.PublishedDate.ToString('yyyy-MM-dd')))"
                }
            }

            if ($issues.Count -eq 0) {
                Write-ModernOutput "No security issues found" -Level Success
            } else {
                foreach ($issue in $issues) {
                    Write-ModernOutput $issue -Level Warning
                }
            }
        }
        catch {
            Write-ModernOutput "Audit failed: $($_.Exception.Message)" -Level Error
            exit 1
        }
    }
}
