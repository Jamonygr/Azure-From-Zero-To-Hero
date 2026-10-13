[CmdletBinding(DefaultParameterSetName = 'Check')]
param(
  [Parameter(ParameterSetName = 'Check')]
  [switch]$Check,

  [Parameter(Mandatory, ParameterSetName = 'Write')]
  [switch]$Write
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$CatalogPath = Join-Path $Root 'curriculum/lessons.psd1'
$Catalog = Import-PowerShellDataFile -LiteralPath $CatalogPath
$Lessons = @($Catalog.Lessons)
$Drift = [System.Collections.Generic.List[string]]::new()
$null = $Check
$WriteMode = $Write.IsPresent

function Get-LessonById {
  param([AllowNull()][string]$Id)

  if (-not $Id) {
    return $null
  }

  return $Lessons | Where-Object Id -EQ $Id | Select-Object -First 1
}

function Get-RootLessonLink {
  param([hashtable]$Lesson)

  return "[$($Lesson.Id)]($($Lesson.Folder)/README.md)"
}

function Get-NavigationBlock {
  param([hashtable]$Lesson)

  $previous = Get-LessonById -Id $Lesson.Navigation.Previous
  $next = Get-LessonById -Id $Lesson.Navigation.Next
  $parts = [System.Collections.Generic.List[string]]::new()

  if ($previous) {
    $parts.Add("[&larr; $($previous.Id) - $($previous.Title)](../$($previous.Folder)/README.md)")
  }
  else {
    $parts.Add('[&larr; Curriculum](../README.md#curriculum)')
  }

  $parts.Add('[Curriculum](../README.md#curriculum)')

  if ($next) {
    $parts.Add("[$($next.Id) - $($next.Title) &rarr;](../$($next.Folder)/README.md)")
  }
  else {
    $parts.Add('[Curriculum &rarr;](../README.md#curriculum)')
  }

  return @(
    '<!-- lesson-navigation:start -->'
    $parts -join ' | '
    '<!-- lesson-navigation:end -->'
  ) -join "`n"
}

function Get-CurriculumBlock {
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add('<!-- curriculum:start -->')
  $lines.Add('| ID | Lesson | Phase | Prerequisites | Cost | Run mode |')
  $lines.Add('|---|---|---|---|---|---|')

  foreach ($lesson in $Lessons) {
    $prerequisites = if (@($lesson.Prerequisites).Count -eq 0) {
      'None'
    }
    else {
      (@($lesson.Prerequisites) | ForEach-Object {
          $prerequisite = Get-LessonById -Id $_
          Get-RootLessonLink -Lesson $prerequisite
        }) -join ', '
    }

    $link = "[$($lesson.Id) - $($lesson.Title)]($($lesson.Folder)/README.md)"
    $lines.Add("| $($lesson.Id) | $link | $($lesson.Phase) | $prerequisites | $($lesson.CostTier) | $($lesson.DeploymentMode) |")
  }

  $lines.Add('<!-- curriculum:end -->')
  return $lines -join "`n"
}

function Set-MarkedBlock {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Marker,

    [Parameter(Mandatory)]
    [string]$Replacement
  )

  $content = Get-Content -LiteralPath $Path -Raw
  $newline = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }
  $start = "<!-- ${Marker}:start -->"
  $end = "<!-- ${Marker}:end -->"
  $pattern = [regex]::Escape($start) + '[\s\S]*?' + [regex]::Escape($end)
  $blockMatches = [regex]::Matches($content, $pattern)

  if ($blockMatches.Count -ne 1) {
    throw "$Path must contain exactly one $start / $end block; found $($blockMatches.Count)."
  }

  $expected = $Replacement.Replace("`n", $newline)
  if ($blockMatches[0].Value -ceq $expected) {
    return
  }

  $relativePath = [System.IO.Path]::GetRelativePath($Root, $Path)
  if ($WriteMode) {
    $updated = [regex]::Replace(
      $content,
      $pattern,
      [System.Text.RegularExpressions.MatchEvaluator]{ $expected },
      1
    )
    Set-Content -LiteralPath $Path -Value $updated -Encoding utf8 -NoNewline
    Write-Host "Updated $relativePath"
  }
  else {
    $Drift.Add($relativePath)
  }
}

if ($Catalog.SchemaVersion -ne 1) {
  throw "Unsupported curriculum schema version '$($Catalog.SchemaVersion)'."
}

$requiredFields = @(
  'Id',
  'Folder',
  'Title',
  'Phase',
  'Prerequisites',
  'Diagram',
  'CostTier',
  'DeploymentMode',
  'Navigation'
)
$ids = @($Lessons.Id)
$folders = @($Lessons.Folder)

if (($ids | Sort-Object -Unique).Count -ne $ids.Count) {
  throw 'Curriculum lesson IDs must be unique.'
}

if (($folders | Sort-Object -Unique).Count -ne $folders.Count) {
  throw 'Curriculum lesson folders must be unique.'
}

foreach ($lesson in $Lessons) {
  foreach ($field in $requiredFields) {
    if (-not $lesson.ContainsKey($field)) {
      throw "Lesson '$($lesson.Id)' is missing required field '$field'."
    }
  }

  if ($lesson.Id -notmatch '^CLZ-\d{3}$') {
    throw "Lesson ID '$($lesson.Id)' must match CLZ-###."
  }

  $lessonFolder = Join-Path $Root $lesson.Folder
  $readmePath = Join-Path $lessonFolder 'README.md'
  $diagramPath = Join-Path $Root "assets/diagrams/$($lesson.Diagram)"

  if (-not (Test-Path -LiteralPath $lessonFolder -PathType Container)) {
    throw "Catalog folder '$($lesson.Folder)' does not exist."
  }

  if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
    throw "Catalog README '$($lesson.Folder)/README.md' does not exist."
  }

  if (-not (Test-Path -LiteralPath $diagramPath -PathType Leaf)) {
    throw "Catalog diagram 'assets/diagrams/$($lesson.Diagram)' does not exist."
  }

  foreach ($prerequisiteId in @($lesson.Prerequisites)) {
    if ($prerequisiteId -notin $ids) {
      throw "Lesson '$($lesson.Id)' has unknown prerequisite '$prerequisiteId'."
    }
  }

  foreach ($navigationId in @($lesson.Navigation.Previous, $lesson.Navigation.Next)) {
    if ($navigationId -and $navigationId -notin $ids) {
      throw "Lesson '$($lesson.Id)' has unknown navigation target '$navigationId'."
    }
  }
}

$diskFolders = @(
  Get-ChildItem -LiteralPath $Root -Directory -Filter 'CLZ-*' |
    Sort-Object Name |
    Select-Object -ExpandProperty Name
)
$unregisteredFolders = @($diskFolders | Where-Object { $_ -notin $folders })

if ($unregisteredFolders.Count -gt 0) {
  throw "Lesson folders missing from the catalog: $($unregisteredFolders -join ', ')."
}

Set-MarkedBlock -Path (Join-Path $Root 'README.md') -Marker 'curriculum' -Replacement (Get-CurriculumBlock)

foreach ($lesson in $Lessons) {
  $lessonReadme = Join-Path $Root "$($lesson.Folder)/README.md"
  Set-MarkedBlock -Path $lessonReadme -Marker 'lesson-navigation' -Replacement (Get-NavigationBlock -Lesson $lesson)
}

if ($Drift.Count -gt 0) {
  throw "Curriculum content is out of date: $($Drift -join ', '). Run this script with -Write."
}

if ($WriteMode) {
  Write-Host 'Curriculum blocks are synchronized.'
}
else {
  Write-Host 'Curriculum blocks are current.'
}
