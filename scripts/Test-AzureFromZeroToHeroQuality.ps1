param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$Terraform,
  [switch]$Docs,
  [switch]$PowerShell,
  [switch]$Markdown,
  [switch]$TerraformLint,
  [switch]$Security,
  [switch]$PlanSafeLessons,
  [string]$ReportPath = "artifacts\quality-report.json"
)

$ErrorActionPreference = "Stop"

if (-not ($Terraform -or $Docs -or $PowerShell -or $Markdown -or $TerraformLint -or $Security -or $PlanSafeLessons)) {
  $Terraform = $true
  $Docs = $true
  $PowerShell = $true
  $Markdown = $true
  $TerraformLint = $true
  $Security = $true
}

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

  $cmd = Get-Command $Command -ErrorAction SilentlyContinue
  if (-not $cmd) {
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

try {
  if ($Terraform) {
    Invoke-QualityStep -Name "terraform-format-validate" -ScriptBlock {
      & (Join-Path $Root "scripts\Test-AzureFromZeroToHeroTerraform.ps1") `
        -Format `
        -Validate `
        -ReportPath (Join-Path $reportDirectory "terraform-validation-report.json")
    }
  }

  if ($Docs) {
    Invoke-QualityStep -Name "repo-docs" -ScriptBlock {
      & (Join-Path $Root "scripts\Test-AzureFromZeroToHeroDocs.ps1") `
        -ReportPath (Join-Path $reportDirectory "repo-quality-report.json")
    }
  }

  if ($PowerShell) {
    Invoke-QualityStep -Name "powershell-analysis" -ScriptBlock {
      $module = Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
      if (-not $module) {
        throw "PSScriptAnalyzer is not installed. Run: Install-Module PSScriptAnalyzer -Scope CurrentUser"
      }

      Import-Module PSScriptAnalyzer -ErrorAction Stop
      $settingsPath = Join-Path $Root "PSScriptAnalyzerSettings.psd1"
      $scriptPath = Join-Path $Root "scripts"
      $analysis = @(Invoke-ScriptAnalyzer -Path $scriptPath -Recurse -Settings $settingsPath)
      $analysis | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $reportDirectory "powershell-analysis-report.json") -Encoding utf8

      $blocking = @($analysis | Where-Object { $_.Severity -eq "Error" })
      if ($blocking.Count -gt 0) {
        throw "$($blocking.Count) blocking PSScriptAnalyzer issue(s) found."
      }
    }
  }

  if ($Markdown) {
    Invoke-QualityStep -Name "markdownlint" -ScriptBlock {
      Invoke-LoggedCommand -Name "markdownlint" -Command "npx" -Arguments @("--yes", "markdownlint-cli2@0.22.1") -LogFile "markdownlint-report.txt"
    }
  }

  if ($TerraformLint) {
    Invoke-QualityStep -Name "tflint" -ScriptBlock {
      Invoke-LoggedCommand -Name "tflint-init" -Command "tflint" -Arguments @("--init", "--config", (Join-Path $Root ".tflint.hcl")) -LogFile "tflint-init-report.txt"
      Invoke-LoggedCommand -Name "tflint" -Command "tflint" -Arguments @("--recursive", "--config", (Join-Path $Root ".tflint.hcl"), "--minimum-failure-severity=error", "--format", "compact") -LogFile "tflint-report.txt"
    }
  }

  if ($Security) {
    Invoke-QualityStep -Name "trivy-config" -ScriptBlock {
      Invoke-LoggedCommand -Name "trivy-report" -Command "trivy" -Arguments @("config", "--ignorefile", (Join-Path $Root ".trivyignore"), "--severity", "MEDIUM,HIGH,CRITICAL", "--format", "table", "--output", (Join-Path $reportDirectory "trivy-config-report.txt"), "--exit-code", "0", $Root) -LogFile "trivy-report-command.txt"
      Invoke-LoggedCommand -Name "trivy-critical-gate" -Command "trivy" -Arguments @("config", "--ignorefile", (Join-Path $Root ".trivyignore"), "--severity", "CRITICAL", "--format", "table", "--exit-code", "1", $Root) -LogFile "trivy-critical-report.txt"
    }
  }

  if ($PlanSafeLessons) {
    Invoke-QualityStep -Name "terraform-safe-plans" -ScriptBlock {
      & (Join-Path $Root "scripts\Test-AzureFromZeroToHeroTerraform.ps1") `
        -PlanSafeLessons `
        -ReportPath (Join-Path $reportDirectory "terraform-plan-report.json")
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
