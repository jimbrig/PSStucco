#Requires -Version 7.0

[CmdletBinding(DefaultParameterSetName = 'Task')]
param(
    # Build task(s) to execute
    [Parameter(ParameterSetName = 'Task', Position = 0)]
    [ArgumentCompleter({
        param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
        $psakeFile = './psakeFile.ps1'
        switch ($Parameter) {
            'Task' {
                if ([string]::IsNullOrEmpty($WordToComplete)) {
                    Get-PSakeScriptTasks -BuildFile $psakeFile | Select-Object -ExpandProperty Name
                } else {
                    Get-PSakeScriptTasks -BuildFile $psakeFile |
                        Where-Object { $_.Name -match $WordToComplete } |
                        Select-Object -ExpandProperty Name
                }
            }
                Default { }
            }
        })]
    [string[]]$Task = 'default',

    # Bootstrap dependencies
    [switch]$Bootstrap,

    # List available build tasks
    [Parameter(ParameterSetName = 'Help')]    [switch]$Help,

    # Optional properties to pass to psake
    [hashtable]$Properties,

    # Optional parameters to pass to psake
    [hashtable]$Parameters,

    # Force reinstall of dependencies
    [switch]$Force,

    # Use prerelease versions
    [switch]$Prerelease
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Modern PowerShell bootstrap function using PSResourceGet
function Initialize-ModernBuildEnvironment {
    [CmdletBinding()]
    param(
        [switch]$Force,
        [switch]$Prerelease
    )

    Write-Host '🚀 Initializing modern PowerShell build environment...' -ForegroundColor Cyan

    try {
        # Check PowerShell version
        if ($PSVersionTable.PSVersion -lt [version]'7.0') {
            throw "PowerShell 7.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
        }

        # Install/Update Microsoft.PowerShell.PSResourceGet if needed
        Write-Host '📦 Ensuring Microsoft.PowerShell.PSResourceGet is available...' -ForegroundColor Yellow

        $psResourceGet = Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

        if (-not $psResourceGet -or $psResourceGet.Version -lt [version]'1.0.0' -or $Force) {
            Write-Host 'Installing/Updating Microsoft.PowerShell.PSResourceGet...' -ForegroundColor Yellow

            # Install PSResourceGet using the old method first if not available
            if (-not $psResourceGet) {
                Install-Module Microsoft.PowerShell.PSResourceGet -Force -Scope CurrentUser -AllowClobber -Repository PSGallery
            }
        }

        # Import PSResourceGet
        Import-Module Microsoft.PowerShell.PSResourceGet -Force

        # Register PSGallery repository if not already registered
        $psGallery = Get-PSResourceRepository -Name PSGallery -ErrorAction SilentlyContinue
        if (-not $psGallery) {
            Write-Host 'Registering PSGallery repository...' -ForegroundColor Yellow
            Register-PSResourceRepository -PSGallery
        } elseif ($psGallery.Trusted -eq $false) {
            Write-Host 'Setting PSGallery as trusted...' -ForegroundColor Yellow
            Set-PSResourceRepository -Name PSGallery -Trusted
        }

        # Load requirements
        $requirementsPath = Join-Path $PSScriptRoot 'requirements.psd1'
        if (-not (Test-Path $requirementsPath)) {
            Write-Warning "Requirements file not found: $requirementsPath. Skipping dependency installation."
            return $true
        }

        $requirements = Import-PowerShellDataFile -Path $requirementsPath
        Write-Host "📋 Found $($requirements.Keys.Count - 1) module dependencies" -ForegroundColor Green

        # Install required modules using PSResourceGet
        foreach ($moduleName in $requirements.Keys) {
            if ($moduleName -eq 'PSDependOptions') { continue }

            $moduleInfo = $requirements[$moduleName]
            $installParams = @{
                Name            = $moduleName
                Scope           = 'CurrentUser'
                TrustRepository = $true
            }

            if ($Force) { $installParams.Reinstall = $true }

            # Handle version specification
            if ($moduleInfo -is [hashtable] -and $moduleInfo.Version -and $moduleInfo.Version -ne 'latest') {
                $installParams.Version = $moduleInfo.Version
            }

            # Handle prerelease
            if ($Prerelease -or ($moduleInfo -is [hashtable] -and $moduleInfo.Prerelease)) {
                $installParams.Prerelease = $true
            }

            try {
                Write-Host "📥 Installing/Updating module: $moduleName" -ForegroundColor Yellow

                # Check if module is already installed
                $installedModule = Get-PSResource -Name $moduleName -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1

                if ($installedModule -and -not $Force) {
                    Write-Host "✅ Module $moduleName is already installed (v$($installedModule.Version))" -ForegroundColor Green
                } else {
                    Install-PSResource @installParams
                    Write-Host "✅ Successfully installed: $moduleName" -ForegroundColor Green
                }
            } catch {
                Write-Error "Failed to install module '$moduleName' via PSResourceGet: $($_.Exception.Message)"
            }
        }

        # Import critical modules
        $criticalModules = @('psake', 'BuildHelpers', 'Pester', 'PSScriptAnalyzer')
        foreach ($module in $criticalModules) {
            try {
                if (Get-Module $module -ListAvailable) {
                    Import-Module $module -Force -Global
                    Write-Host "✅ Imported: $module" -ForegroundColor Green
                }
            } catch {
                Write-Warning "Failed to import module '$module': $($_.Exception.Message)"
            }
        }

        Write-Host '🎉 Build environment initialization completed successfully!' -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Build environment initialization failed: $($_.Exception.Message)"
        return $false
    }
}

# Bootstrap dependencies
if ($Bootstrap.IsPresent) {
    $initResult = Initialize-ModernBuildEnvironment -Force:$Force -Prerelease:$Prerelease
    if (-not $initResult) {
        throw 'Bootstrap failed'
    }
}

# Execute psake task(s)
$psakeFile = Join-Path $PSScriptRoot 'psakeFile.ps1'

try {
    if ($PSCmdlet.ParameterSetName -eq 'Help') {
        # Display available tasks
        Write-Host "🔍 Available build tasks:" -ForegroundColor Cyan
        Get-PSakeScriptTasks -BuildFile $psakeFile |
            Format-Table -Property Name, Description, Alias, DependsOn -AutoSize
    } else {
        # Ensure BuildHelpers environment is set
        if (Get-Module BuildHelpers -ListAvailable) {
            Set-BuildEnvironment -Force
        }

        Write-Host "🚀 Executing psake tasks: $($Task -join ', ')" -ForegroundColor Cyan
        Invoke-psake -BuildFile $psakeFile -TaskList $Task -NoLogo -Properties $Properties -Parameters $Parameters

        # Exit with appropriate code
        $exitCode = [int](-not $psake.build_success)
        if ($exitCode -eq 0) {
            Write-Host "✅ Build completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Build failed!" -ForegroundColor Red
        }
        exit $exitCode
    }
}
catch {
    Write-Error "Build script failed: $($_.Exception.Message)"
    exit 1
}
