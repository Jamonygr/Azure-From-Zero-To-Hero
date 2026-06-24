param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$Format,
  [switch]$Validate,
  [switch]$PlanSafeLessons,
  [string]$ReportPath
)

$ErrorActionPreference = "Stop"

if (-not ($Format -or $Validate -or $PlanSafeLessons)) {
  $Format = $true
}

$results = [System.Collections.Generic.List[object]]::new()
$failureCount = 0

function Add-Result {
  param(
    [string]$Mode,
    [string]$Lesson,
    [string]$CommandLine,
    [string]$Status,
    [double]$DurationSeconds,
    [string]$Message
  )

  $results.Add([pscustomobject]@{
      mode             = $Mode
      lesson           = $Lesson
      command          = $CommandLine
      status           = $Status
      duration_seconds = [math]::Round($DurationSeconds, 2)
      message          = $Message
    })
}

function Invoke-RepoStep {
  param(
    [string]$Mode,
    [string]$Lesson,
    [string]$WorkingDirectory,
    [string]$Command,
    [string[]]$Arguments
  )

  $commandLine = "$Command $($Arguments -join ' ')".Trim()
  $timer = [System.Diagnostics.Stopwatch]::StartNew()
  Push-Location $WorkingDirectory
  try {
    $output = & $Command @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }

    if ($exitCode -ne 0) {
      throw "Exit code $exitCode`n$($output -join "`n")"
    }

    $timer.Stop()
    Add-Result -Mode $Mode -Lesson $Lesson -CommandLine $commandLine -Status "passed" -DurationSeconds $timer.Elapsed.TotalSeconds -Message "OK"
    Write-Host "[$Mode] PASS $Lesson"
  }
  catch {
    $timer.Stop()
    $script:failureCount++
    Add-Result -Mode $Mode -Lesson $Lesson -CommandLine $commandLine -Status "failed" -DurationSeconds $timer.Elapsed.TotalSeconds -Message $_.Exception.Message
    Write-Host "[$Mode] FAIL $Lesson"
    Write-Host $_.Exception.Message
  }
  finally {
    Pop-Location
  }
}

function Get-LessonFolders {
  Get-ChildItem -Path $Root -Directory -Filter "CLZ-*" | Sort-Object Name
}

function Write-ValidationReport {
  if (-not $ReportPath) {
    return
  }

  $resolvedReportPath = if ([System.IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath
  }
  else {
    Join-Path $Root $ReportPath
  }

  $reportDirectory = Split-Path -Parent $resolvedReportPath
  if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
    New-Item -ItemType Directory -Path $reportDirectory | Out-Null
  }

  [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    root             = $Root
    failed_steps     = $failureCount
    results          = $results
  } | ConvertTo-Json -Depth 8 | Set-Content -Path $resolvedReportPath -Encoding utf8
}

$safePlanExclusions = @(
  "CLZ-300-public-dns-optional",
  "CLZ-320-cross-environment-state"
)

Push-Location $Root
try {
  if ($Format) {
    Invoke-RepoStep -Mode "format" -Lesson "." -WorkingDirectory $Root -Command "terraform" -Arguments @("fmt", "-check", "-recursive")
  }

  if ($Validate) {
    foreach ($folder in Get-LessonFolders) {
      Invoke-RepoStep -Mode "init" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments @("init", "-backend=false", "-input=false", "-no-color")
      Invoke-RepoStep -Mode "validate" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments @("validate", "-no-color")
    }
  }

  if ($PlanSafeLessons) {
    foreach ($folder in Get-LessonFolders) {
      if ($safePlanExclusions -contains $folder.Name) {
        Add-Result -Mode "plan" -Lesson $folder.Name -CommandLine "terraform plan -refresh=false -input=false -lock=false -no-color" -Status "skipped" -DurationSeconds 0 -Message "Excluded because the lesson depends on owned DNS or existing remote state."
        Write-Host "[plan] SKIP $($folder.Name)"
        continue
      }

      Invoke-RepoStep -Mode "init" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments @("init", "-backend=false", "-input=false", "-no-color")
      Invoke-RepoStep -Mode "plan" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments @("plan", "-refresh=false", "-input=false", "-lock=false", "-no-color")
    }
  }
}
finally {
  Pop-Location
  Write-ValidationReport
}

if ($failureCount -gt 0) {
  throw "$failureCount Terraform validation step(s) failed."
}
