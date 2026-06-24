param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$ReportPath
)

$ErrorActionPreference = "Stop"

$results = [System.Collections.Generic.List[object]]::new()
$failureCount = 0

function Add-CheckResult {
  param(
    [string]$Check,
    [string]$Target,
    [string]$Status,
    [string]$Message
  )

  if ($Status -eq "failed") {
    $script:failureCount++
  }

  $results.Add([pscustomobject]@{
      check   = $Check
      target  = $Target
      status  = $Status
      message = $Message
    })
}

function Resolve-MarkdownTarget {
  param(
    [System.IO.FileInfo]$MarkdownFile,
    [string]$Target
  )

  $cleanTarget = $Target.Trim()
  if ($cleanTarget.StartsWith("<") -and $cleanTarget.EndsWith(">")) {
    $cleanTarget = $cleanTarget.Substring(1, $cleanTarget.Length - 2)
  }

  if ($cleanTarget -match '^(https?|mailto):' -or $cleanTarget.StartsWith("#")) {
    return $null
  }

  $pathOnly = ($cleanTarget -split '#')[0]
  if ([string]::IsNullOrWhiteSpace($pathOnly)) {
    return $null
  }

  $pathOnly = [System.Uri]::UnescapeDataString($pathOnly)
  if ([System.IO.Path]::IsPathRooted($pathOnly)) {
    return $pathOnly
  }

  return Join-Path $MarkdownFile.DirectoryName $pathOnly
}

Push-Location $Root
try {
  $markdownFiles = Get-ChildItem -Path $Root -Recurse -File -Filter "*.md" |
    Where-Object { $_.FullName -notmatch '\\.terraform\\' }

  foreach ($file in $markdownFiles) {
    $content = Get-Content -Raw -Path $file.FullName
    $matches = [regex]::Matches($content, '!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')

    foreach ($match in $matches) {
      $target = $match.Groups[1].Value
      $resolvedTarget = Resolve-MarkdownTarget -MarkdownFile $file -Target $target
      if (-not $resolvedTarget) {
        continue
      }

      if (Test-Path -LiteralPath $resolvedTarget) {
        Add-CheckResult -Check "markdown-link" -Target "$($file.FullName) -> $target" -Status "passed" -Message "OK"
      }
      else {
        Add-CheckResult -Check "markdown-link" -Target "$($file.FullName) -> $target" -Status "failed" -Message "Target does not exist: $resolvedTarget"
      }
    }
  }

  $powerShellFiles = Get-ChildItem -Path $Root -Recurse -File -Filter "*.ps1" |
    Where-Object { $_.FullName -notmatch '\\.terraform\\' }

  foreach ($file in $powerShellFiles) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null

    if ($parseErrors.Count -eq 0) {
      Add-CheckResult -Check "powershell-parse" -Target $file.FullName -Status "passed" -Message "OK"
    }
    else {
      Add-CheckResult -Check "powershell-parse" -Target $file.FullName -Status "failed" -Message (($parseErrors | ForEach-Object { $_.Message }) -join "; ")
    }
  }

  $requiredLessonSections = @(
    "## Cost Awareness",
    "## Validation Checklist",
    "## Cleanup",
    "## Next Lesson"
  )

  foreach ($folder in Get-ChildItem -Path $Root -Directory -Filter "CLZ-*" | Sort-Object Name) {
    $readme = Join-Path $folder.FullName "README.md"
    if (-not (Test-Path -LiteralPath $readme)) {
      Add-CheckResult -Check "lesson-readme" -Target $folder.Name -Status "failed" -Message "README.md is missing."
      continue
    }

    $content = Get-Content -Raw -Path $readme
    foreach ($section in $requiredLessonSections) {
      if ($content.Contains($section)) {
        Add-CheckResult -Check "lesson-readme" -Target "$($folder.Name) $section" -Status "passed" -Message "OK"
      }
      else {
        Add-CheckResult -Check "lesson-readme" -Target "$($folder.Name) $section" -Status "failed" -Message "Required section is missing."
      }
    }
  }
}
finally {
  Pop-Location
}

if ($ReportPath) {
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
    failed_checks    = $failureCount
    results          = $results
  } | ConvertTo-Json -Depth 8 | Set-Content -Path $resolvedReportPath -Encoding utf8
}

if ($failureCount -gt 0) {
  throw "$failureCount repository documentation or script check(s) failed."
}

Write-Host "Repository documentation and script checks passed."
