[CmdletBinding()]
param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$Format,
  [switch]$Validate,
  [switch]$Test,
  [switch]$LockfileReadonly,
  [switch]$PlanAuthenticatedLessons,
  [string]$SubscriptionId,
  [string]$ReportPath
)

$ErrorActionPreference = "Stop"

if (-not ($Format -or $Validate -or $Test -or $PlanAuthenticatedLessons)) {
  $Format = $true
}

if ($PlanAuthenticatedLessons -and [string]::IsNullOrWhiteSpace($SubscriptionId)) {
  throw "-PlanAuthenticatedLessons requires an explicit -SubscriptionId. No Azure account is selected implicitly."
}

$results = [System.Collections.Generic.List[object]]::new()
$failureCount = 0

function Protect-SubscriptionDetail {
  param([AllowEmptyString()][string]$Text)

  if ([string]::IsNullOrEmpty($Text)) {
    return $Text
  }

  $protectedText = [regex]::Replace(
    $Text,
    '(?i)(/subscriptions/)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    '$1<masked-subscription-id>'
  )
  if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
    $protectedText = [regex]::Replace(
      $protectedText,
      [regex]::Escape($SubscriptionId),
      '<masked-subscription-id>',
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
  }

  return $protectedText
}

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
  $commandLine = Protect-SubscriptionDetail -Text $commandLine
  $timer = [System.Diagnostics.Stopwatch]::StartNew()
  Push-Location $WorkingDirectory
  try {
    $output = & $Command @Arguments 2>&1 | ForEach-Object { Protect-SubscriptionDetail -Text $_.ToString() }
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
    $protectedMessage = Protect-SubscriptionDetail -Text $_.Exception.Message
    Add-Result -Mode $Mode -Lesson $Lesson -CommandLine $commandLine -Status "failed" -DurationSeconds $timer.Elapsed.TotalSeconds -Message $protectedMessage
    Write-Host "[$Mode] FAIL $Lesson"
    Write-Host $protectedMessage
  }
  finally {
    Pop-Location
  }
}

function Get-LessonFolder {
  Get-ChildItem -Path $Root -Directory -Filter "CLZ-*" |
    Where-Object { Get-ChildItem -Path $_.FullName -File -Filter "*.tf" -ErrorAction SilentlyContinue } |
    Sort-Object Name
}

function Get-TerraformTestFolder {
  $candidateFolders = @(
    Get-LessonFolder
    Get-ChildItem -Path (Join-Path $Root "modules") -Directory -ErrorAction SilentlyContinue
  )

  $candidateFolders |
    Where-Object {
      $testDirectory = Join-Path $_.FullName "tests"
      (Test-Path -LiteralPath $testDirectory -PathType Container) -and
      @(Get-ChildItem -Path $testDirectory -File -Filter "*.tftest.hcl" -ErrorAction SilentlyContinue).Count -gt 0
    } |
    Sort-Object FullName -Unique
}

function Write-ValidationReport {
  param([string]$Destination)

  if ([string]::IsNullOrWhiteSpace($Destination)) {
    return
  }

  $resolvedReportPath = if ([System.IO.Path]::IsPathRooted($Destination)) {
    $Destination
  }
  else {
    Join-Path $Root $Destination
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

$planExclusions = @(
  "CLZ-090-optional-vscode-terraform-powershell-setup",
  "CLZ-100-foundations",
  "CLZ-110-windows-workstation-setup",
  "CLZ-300-public-dns-optional",
  "CLZ-320-cross-environment-state"
)

if ($PlanAuthenticatedLessons) {
  $accountId = & az account show --query id --output tsv 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $accountId) {
    throw "Azure CLI is not signed in. Run az login, select the intended lab subscription, and retry."
  }

  if ($accountId -ne $SubscriptionId) {
    throw "The active Azure CLI account does not match -SubscriptionId. Account details are intentionally masked."
  }

  Write-Warning "Authenticated Terraform plans can query Azure and may trigger provider behavior. This command never applies changes."
}

Push-Location $Root
try {
  if ($Format) {
    Invoke-RepoStep -Mode "format" -Lesson "." -WorkingDirectory $Root -Command "terraform" -Arguments @("fmt", "-check", "-recursive")
  }

  if ($Validate) {
    foreach ($folder in Get-LessonFolder) {
      $initArguments = @("init", "-backend=false", "-input=false", "-no-color")
      if ($LockfileReadonly) {
        $initArguments += "-lockfile=readonly"
      }

      Invoke-RepoStep -Mode "init" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments $initArguments
      Invoke-RepoStep -Mode "validate" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments @("validate", "-no-color")
    }
  }

  if ($Test) {
    foreach ($folder in Get-TerraformTestFolder) {
      $relativeFolder = [System.IO.Path]::GetRelativePath($Root, $folder.FullName).Replace("\", "/")
      $initArguments = @("init", "-backend=false", "-input=false", "-no-color")
      if ($LockfileReadonly) {
        $initArguments += "-lockfile=readonly"
      }

      Invoke-RepoStep -Mode "test-init" -Lesson $relativeFolder -WorkingDirectory $folder.FullName -Command "terraform" -Arguments $initArguments
      Invoke-RepoStep -Mode "test" -Lesson $relativeFolder -WorkingDirectory $folder.FullName -Command "terraform" -Arguments @("test", "-no-color")
    }
  }

  if ($PlanAuthenticatedLessons) {
    foreach ($folder in Get-LessonFolder) {
      if ($planExclusions -contains $folder.Name) {
        Add-Result -Mode "plan" -Lesson $folder.Name -CommandLine "terraform plan" -Status "skipped" -DurationSeconds 0 -Message "Excluded because this lesson is credential-free, opt-in, or depends on existing remote state."
        Write-Host "[plan] SKIP $($folder.Name)"
        continue
      }

      $initArguments = @("init", "-backend=false", "-input=false", "-no-color")
      if ($LockfileReadonly) {
        $initArguments += "-lockfile=readonly"
      }

      Invoke-RepoStep -Mode "init" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments $initArguments
      Invoke-RepoStep -Mode "plan" -Lesson $folder.Name -WorkingDirectory $folder.FullName -Command "terraform" -Arguments @(
        "plan",
        "-refresh=false",
        "-input=false",
        "-lock=false",
        "-no-color",
        "-var-file=terraform.tfvars.example",
        "-var",
        "subscription_id=$SubscriptionId"
      )
    }
  }
}
finally {
  Pop-Location
  Write-ValidationReport -Destination $ReportPath
}

if ($failureCount -gt 0) {
  throw "$failureCount Terraform validation step(s) failed."
}
