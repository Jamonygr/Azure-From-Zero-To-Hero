[CmdletBinding()]
param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$Terraform,
  [switch]$Docs,
  [switch]$PowerShell,
  [switch]$Pester,
  [switch]$Curriculum,
  [switch]$Actionlint,
  [switch]$Markdown,
  [switch]$TerraformLint,
  [switch]$Security,
  [string]$ReportPath = "artifacts\quality-report.json"
)

$ErrorActionPreference = "Stop"

if (-not ($Terraform -or $Docs -or $PowerShell -or $Pester -or $Curriculum -or $Actionlint -or $Markdown -or $TerraformLint -or $Security)) {
  $Terraform = $true
  $Docs = $true
  $PowerShell = $true
  $Pester = $true
  $Curriculum = $true
  $Actionlint = $true
  $Markdown = $true
  $TerraformLint = $true
  $Security = $true
}

$toolManifest = Import-PowerShellDataFile -Path (Join-Path $Root ".config\tool-versions.psd1")
$results = [System.Collections.Generic.List[object]]::new()
$failureCount = 0

function Resolve-RepoPath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }

  return Join-Path $Root $Path
}

$resolvedReportPath = Resolve-RepoPath -Path $ReportPath
$reportDirectory = Split-Path -Parent $resolvedReportPath
if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
  New-Item -ItemType Directory -Path $reportDirectory | Out-Null
}

function Add-QualityResult {
  param(
    [string]$Check,
    [string]$Status,
    [double]$DurationSeconds,
    [string]$Message
  )

  $results.Add([pscustomobject]@{
      check            = $Check
      status           = $Status
      duration_seconds = [math]::Round($DurationSeconds, 2)
      message          = $Message
    })
}

function Write-QualityReport {
  [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    root             = $Root
    failed_steps     = $failureCount
    results          = $results
  } | ConvertTo-Json -Depth 8 | Set-Content -Path $resolvedReportPath -Encoding utf8
}

function Invoke-QualityStep {
  param(
    [string]$Name,
    [scriptblock]$ScriptBlock
  )

  $timer = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    Write-Host "[$Name] START"
    & $ScriptBlock
    $timer.Stop()
    Add-QualityResult -Check $Name -Status "passed" -DurationSeconds $timer.Elapsed.TotalSeconds -Message "OK"
    Write-Host "[$Name] PASS"
  }
  catch {
    $timer.Stop()
    $script:failureCount++
    Add-QualityResult -Check $Name -Status "failed" -DurationSeconds $timer.Elapsed.TotalSeconds -Message $_.Exception.Message
    Write-Host "[$Name] FAIL"
    Write-Host $_.Exception.Message
  }
}

function Invoke-LoggedCommand {
  param(
    [string]$Name,
    [string]$Command,
    [string[]]$Arguments,
    [string]$LogFile
  )

  $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue
  if (-not $commandInfo) {
    throw "$Command was not found on PATH. Install it before running the $Name check locally."
  }

  $logPath = Join-Path $reportDirectory $LogFile
  Push-Location $Root
  try {
    $output = & $Command @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    $output | Set-Content -Path $logPath -Encoding utf8
    foreach ($line in $output) {
      Write-Host $line
    }

    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    if ($exitCode -ne 0) {
      throw "$Command exited with code $exitCode. See $logPath."
    }
  }
  finally {
    Pop-Location
  }
}

function Get-ToolVersion {
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments
  )

  if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
    throw "$Command was not found on PATH."
  }

  $versionOutput = & $Command @Arguments 2>&1 | ForEach-Object { $_.ToString() }
  if ($LASTEXITCODE -ne 0) {
    throw "$Command version detection failed with exit code $LASTEXITCODE."
  }

  $versionMatch = [regex]::Match(($versionOutput -join "`n"), '\d+(?:\.\d+){1,3}')
  if (-not $versionMatch.Success) {
    throw "Could not parse the $Command version."
  }

  return [version]$versionMatch.Value
}

function Confirm-ExactToolVersion {
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments,
    [Parameter(Mandatory)][version]$ExpectedVersion
  )

  $actualVersion = Get-ToolVersion -Command $Command -Arguments $Arguments
  if ($actualVersion -ne $ExpectedVersion) {
    throw "$Command $ExpectedVersion is required by .config/tool-versions.psd1; found $actualVersion."
  }
}

function Confirm-MinimumToolVersion {
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments,
    [Parameter(Mandatory)][version]$MinimumVersion
  )

  $actualVersion = Get-ToolVersion -Command $Command -Arguments $Arguments
  if ($actualVersion -lt $MinimumVersion) {
    throw "$Command $MinimumVersion or newer is required by .config/tool-versions.psd1; found $actualVersion."
  }
}

try {
  if ($Terraform) {
    Invoke-QualityStep -Name "terraform-format-validate-test" -ScriptBlock {
      Confirm-ExactToolVersion -Command "terraform" -Arguments @("version", "-json") -ExpectedVersion ([version]$toolManifest.Runtime.Terraform)
      & (Join-Path $Root "scripts\Test-AzureFromZeroToHeroTerraform.ps1") `
        -Format `
        -Validate `
        -Test `
        -LockfileReadonly `
        -ReportPath (Join-Path $reportDirectory "terraform-validation-report.json")
    }
  }

  if ($Docs) {
    Invoke-QualityStep -Name "repo-docs" -ScriptBlock {
      & (Join-Path $Root "scripts\Test-AzureFromZeroToHeroDocs.ps1") `
        -ReportPath (Join-Path $reportDirectory "repo-quality-report.json")
    }
  }

  if ($Curriculum) {
    Invoke-QualityStep -Name "curriculum-drift" -ScriptBlock {
      & (Join-Path $Root "scripts\Sync-AzureFromZeroToHeroCurriculum.ps1") -Check
    }
  }

  if ($PowerShell) {
    Invoke-QualityStep -Name "powershell-analysis" -ScriptBlock {
      $module = Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
      if (-not $module -or $module.Version -lt [version]$toolManifest.PowerShellModules.PSScriptAnalyzer) {
        throw "PSScriptAnalyzer $($toolManifest.PowerShellModules.PSScriptAnalyzer) or newer is required."
      }

      Import-Module PSScriptAnalyzer -MinimumVersion $toolManifest.PowerShellModules.PSScriptAnalyzer -ErrorAction Stop
      $analysis = @(Invoke-ScriptAnalyzer -Path (Join-Path $Root "scripts") -Recurse -Settings (Join-Path $Root "PSScriptAnalyzerSettings.psd1"))
      $analysis | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $reportDirectory "powershell-analysis-report.json") -Encoding utf8

      $blocking = @($analysis | Where-Object { $_.Severity -in @("Warning", "Error") })
      if ($blocking.Count -gt 0) {
        $summary = $blocking | ForEach-Object { "$($_.ScriptName):$($_.Line) $($_.RuleName) - $($_.Message)" }
        throw "$($blocking.Count) blocking PSScriptAnalyzer issue(s) found.`n$($summary -join "`n")"
      }
    }
  }

  if ($Pester) {
    Invoke-QualityStep -Name "pester" -ScriptBlock {
      $requiredVersion = [version]$toolManifest.PowerShellModules.Pester
      $module = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
      if (-not $module -or $module.Version -lt $requiredVersion) {
        throw "Pester $requiredVersion or newer is required."
      }

      Import-Module Pester -MinimumVersion $requiredVersion -ErrorAction Stop
      $configuration = New-PesterConfiguration
      $configuration.Run.Path = Join-Path $Root "tests"
      $configuration.Run.PassThru = $true
      $configuration.Output.Verbosity = "Detailed"
      $configuration.TestResult.Enabled = $true
      $configuration.TestResult.OutputPath = Join-Path $reportDirectory "pester-results.xml"
      $pesterResult = Invoke-Pester -Configuration $configuration
      $pesterResult | Select-Object Result, TotalCount, PassedCount, FailedCount, SkippedCount, Duration |
        ConvertTo-Json -Depth 4 |
        Set-Content -Path (Join-Path $reportDirectory "pester-summary.json") -Encoding utf8

      if (-not $pesterResult -or $pesterResult.Result -ne "Passed" -or $pesterResult.TotalCount -eq 0 -or $pesterResult.FailedCount -gt 0) {
        throw "Pester did not complete successfully. Inspect the test result and any framework errors."
      }
    }
  }

  if ($Actionlint) {
    Invoke-QualityStep -Name "actionlint" -ScriptBlock {
      Confirm-ExactToolVersion -Command "actionlint" -Arguments @("-version") -ExpectedVersion ([version]$toolManifest.Runtime.Actionlint)
      $workflowFiles = @(
        Get-ChildItem -Path (Join-Path $Root ".github\workflows") -File |
          Where-Object Name -Match '\.ya?ml$'
        Get-ChildItem -Path (Join-Path $Root "CLZ-370-github-actions-terraform\.github\workflows") -File |
          Where-Object Name -Match '\.ya?ml\.example$'
      )
      if ($workflowFiles.Count -eq 0) {
        throw "No GitHub Actions workflows were found."
      }

      Invoke-LoggedCommand -Name "actionlint" -Command "actionlint" -Arguments @($workflowFiles.FullName) -LogFile "actionlint-report.txt"
    }
  }

  if ($Markdown) {
    Invoke-QualityStep -Name "markdownlint" -ScriptBlock {
      $nodeVersion = Get-ToolVersion -Command "node" -Arguments @("--version")
      if ($nodeVersion.Major -ne [int]$toolManifest.Runtime.NodeMajor -or $nodeVersion -lt [version]$toolManifest.Runtime.NodeMinimum) {
        throw "Node.js major $($toolManifest.Runtime.NodeMajor), version $($toolManifest.Runtime.NodeMinimum) or newer, is required; found $nodeVersion."
      }
      $package = "markdownlint-cli2@$($toolManifest.Runtime.MarkdownLintCli)"
      Invoke-LoggedCommand -Name "markdownlint" -Command "npx" -Arguments @("--yes", $package) -LogFile "markdownlint-report.txt"
    }
  }

  if ($TerraformLint) {
    Invoke-QualityStep -Name "tflint" -ScriptBlock {
      Confirm-MinimumToolVersion -Command "tflint" -Arguments @("--version") -MinimumVersion ([version]$toolManifest.Runtime.TFLint)
      Invoke-LoggedCommand -Name "tflint-init" -Command "tflint" -Arguments @("--init", "--config", (Join-Path $Root ".tflint.hcl")) -LogFile "tflint-init-report.txt"
      $lintFolders = @(
        Get-ChildItem -Path $Root -Directory -Filter "CLZ-*"
        Get-Item -LiteralPath (Join-Path $Root "modules")
      )
      foreach ($lintFolder in $lintFolders) {
        Invoke-LoggedCommand -Name "tflint" -Command "tflint" -Arguments @("--chdir=$($lintFolder.FullName)", "--recursive", "--config", (Join-Path $Root ".tflint.hcl"), "--minimum-failure-severity=warning", "--format", "compact") -LogFile "tflint-$($lintFolder.Name)-report.txt"
      }
    }
  }

  if ($Security) {
    Invoke-QualityStep -Name "trivy-config" -ScriptBlock {
      Confirm-ExactToolVersion -Command "trivy" -Arguments @("--version") -ExpectedVersion ([version]$toolManifest.Runtime.Trivy)
      Invoke-LoggedCommand -Name "trivy" -Command "trivy" -Arguments @(
        "config",
        "--skip-dirs", ".site-docs,.site-docs.tmp,site,.venv,venv,artifacts,.terraform",
        "--ignorefile", (Join-Path $Root ".trivyignore"),
        "--severity", "MEDIUM,HIGH,CRITICAL",
        "--format", "table",
        "--output", (Join-Path $reportDirectory "trivy-config-report.txt"),
        "--exit-code", "1",
        $Root
      ) -LogFile "trivy-command-report.txt"
    }
  }
}
finally {
  Write-QualityReport
}

if ($failureCount -gt 0) {
  throw "$failureCount quality check(s) failed."
}

Write-Host "Azure From Zero To Hero quality checks passed."
