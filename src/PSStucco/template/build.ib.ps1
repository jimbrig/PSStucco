# Invoke-Build Script for PowerShell Module
# Modern alternative to psake with better PowerShell 7+ support

param(
    [string]$Configuration = 'Release',
    [string]$OutputPath = './out',
    [switch]$Clean
)

# Build parameters
$ModuleName = $env:BHProjectName
$ModuleVersion = $env:BHBuildVersion
$ModulePath = $env:BHModulePath

# Tasks
task Clean {
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Recurse -Force
        Write-Build Green "Cleaned output directory: $OutputPath"
    }
}

task Bootstrap {
    Write-Build Yellow "Bootstrapping build dependencies..."

    # Ensure required modules are installed
    $requiredModules = @('Pester', 'PSScriptAnalyzer', 'platyPS', 'PowerShellBuild')
    foreach ($module in $requiredModules) {
        if (-not (Get-Module $module -ListAvailable)) {
            Write-Build Yellow "Installing module: $module"
            Install-PSResource -Name $module -Scope CurrentUser -TrustRepository
        }
    }

    Write-Build Green "Bootstrap completed"
}

task Build Bootstrap, {
    Write-Build Yellow "Building module..."

    $null = New-Item -Path $OutputPath -ItemType Directory -Force

    # Copy module files
    $moduleOutput = Join-Path $OutputPath $ModuleName
    $null = New-Item -Path $moduleOutput -ItemType Directory -Force

    # Copy all module files
    Copy-Item -Path "$ModulePath\*" -Destination $moduleOutput -Recurse -Force

    Write-Build Green "Module built successfully: $moduleOutput"
}

task Test Bootstrap, {
    Write-Build Yellow "Running Pester tests..."

    $testResults = Invoke-Pester -Path './tests' -OutputFormat NUnitXml -OutputFile "$OutputPath/testResults.xml" -PassThru

    if ($testResults.FailedCount -gt 0) {
        throw "Tests failed: $($testResults.FailedCount) failed out of $($testResults.TotalCount)"
    }

    Write-Build Green "All tests passed: $($testResults.PassedCount)/$($testResults.TotalCount)"
}

task Analyze Bootstrap, {
    Write-Build Yellow "Running PSScriptAnalyzer..."

    $analysisResults = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Settings PSGallery

    if ($analysisResults) {
        $analysisResults | Out-String | Write-Build Red
        throw "Script analysis failed with $($analysisResults.Count) issues"
    }

    Write-Build Green "Script analysis passed"
}

task Docs Bootstrap, Build, {
    Write-Build Yellow "Generating documentation..."

    Import-Module "$OutputPath/$ModuleName" -Force

    $docsPath = './docs/en-US'
    $null = New-Item -Path $docsPath -ItemType Directory -Force

    New-MarkdownHelp -Module $ModuleName -OutputFolder $docsPath -Force

    Write-Build Green "Documentation generated: $docsPath"
}

task Package Build, Test, Analyze, {
    Write-Build Yellow "Packaging module..."

    # Create module package
    $packagePath = "$OutputPath/$ModuleName.zip"
    Compress-Archive -Path "$OutputPath/$ModuleName" -DestinationPath $packagePath -Force

    Write-Build Green "Module packaged: $packagePath"
}

task Publish Package, {
    Write-Build Yellow "Publishing to PowerShell Gallery..."

    $apiKey = $env:PSGALLERY_API_KEY
    if (-not $apiKey) {
        throw "PSGALLERY_API_KEY environment variable not set"
    }

    Publish-PSResource -Path "$OutputPath/$ModuleName" -ApiKey $apiKey -Repository PSGallery

    Write-Build Green "Module published to PowerShell Gallery"
}

# Default task
task . Clean, Build, Test, Analyze
