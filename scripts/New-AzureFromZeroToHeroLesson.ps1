[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
  [Parameter(Mandatory)]
  [ValidatePattern('^CLZ-\d{3}$')]
  [string]$Id,

  [Parameter(Mandatory)]
  [ValidatePattern("^[A-Za-z0-9][A-Za-z0-9 _.,:()&+/'-]{0,99}$")]
  [string]$Title,

  [Parameter(Mandatory)]
  [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
  [string]$Slug,

  [Parameter(Mandatory)]
  [ValidateSet('Workstation', 'Foundations', 'Networking', 'Windows compute', 'Platform services', 'Operations')]
  [string]$Phase,

  [Parameter(Mandatory)]
  [ValidatePattern('^[a-z0-9][a-z0-9-]*\.svg$')]
  [ValidateNotNullOrEmpty()]
  [string]$Diagram,

  [ValidateSet('None', 'Low', 'Moderate', 'High')]
  [string]$CostTier = 'Low',

  [ValidateSet('Local only', 'Read-only Azure checks', 'Azure deployment', 'Optional Azure deployment', 'CI examples')]
  [string]$DeploymentMode = 'Azure deployment',

  [string[]]$Prerequisites
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$CatalogPath = Join-Path $Root 'curriculum/lessons.psd1'
$Catalog = Import-PowerShellDataFile -LiteralPath $CatalogPath
$ToolManifest = Import-PowerShellDataFile -LiteralPath (Join-Path $Root '.config/tool-versions.psd1')
$Lessons = @($Catalog.Lessons)
$Id = $Id.ToUpperInvariant()
$Folder = "$($Id)-$Slug"
$LessonPath = Join-Path $Root $Folder
$DiagramPath = Join-Path $Root "assets/diagrams/$Diagram"
$TerraformCommand = Get-Command terraform -ErrorAction SilentlyContinue
$TFLintCommand = Get-Command tflint -ErrorAction SilentlyContinue
$NewNumber = [int]($Id -replace '^CLZ-', '')
$LastLesson = $Lessons[-1]
$LastNumber = [int]($LastLesson.Id -replace '^CLZ-', '')

if ($Lessons.Id -contains $Id) {
  throw "Lesson '$Id' already exists in curriculum/lessons.psd1."
}

if (Test-Path -LiteralPath $LessonPath) {
  throw "Lesson folder '$Folder' already exists."
}

if ($NewNumber -le $LastNumber) {
  throw "New lessons must append after $($LastLesson.Id); choose an ID greater than $($LastLesson.Id)."
}

if (-not (Test-Path -LiteralPath $DiagramPath -PathType Leaf)) {
  throw "Diagram 'assets/diagrams/$Diagram' does not exist. Add it before creating the lesson."
}

if (-not $TerraformCommand) {
  throw "Terraform is required to format the new lesson and create its reviewed provider lockfile."
}

if (-not $TFLintCommand) {
  throw "TFLint is required to verify a generated lesson against the contributor quality policy."
}

$PesterModule = Get-Module -ListAvailable -Name Pester |
  Where-Object Version -EQ ([version]$ToolManifest.PowerShellModules.Pester) |
  Select-Object -First 1
if (-not $PesterModule) {
  throw "Pester $($ToolManifest.PowerShellModules.Pester) is required to verify a generated lesson."
}

& (Join-Path $PSScriptRoot 'Sync-AzureFromZeroToHeroCurriculum.ps1') -Check

if (-not $Prerequisites) {
  $Prerequisites = @($LastLesson.Id)
}

foreach ($prerequisite in $Prerequisites) {
  if ($prerequisite -notin $Lessons.Id) {
    throw "Unknown prerequisite '$prerequisite'."
  }
}

$catalogText = Get-Content -LiteralPath $CatalogPath -Raw
$originalCatalogText = $catalogText
$rootReadmePath = Join-Path $Root 'README.md'
$lastReadmePath = Join-Path $Root "$($LastLesson.Folder)/README.md"
$originalRootReadme = Get-Content -LiteralPath $rootReadmePath -Raw
$originalLastReadme = Get-Content -LiteralPath $lastReadmePath -Raw
$oldNavigation = "Navigation = @{ Previous = '$($LastLesson.Navigation.Previous)'; Next = `$null }"
$newNavigation = "Navigation = @{ Previous = '$($LastLesson.Navigation.Previous)'; Next = '$Id' }"

if (-not $catalogText.Contains($oldNavigation)) {
  throw "Could not find the final navigation entry for $($LastLesson.Id)."
}

$catalogText = $catalogText.Replace($oldNavigation, $newNavigation)
$quotedPrerequisites = ($Prerequisites | ForEach-Object { "'$_'" }) -join ', '
$escapedTitle = $Title.Replace("'", "''")
$catalogEntry = @"
    @{
      Id = '$Id'; Folder = '$Folder'; Title = '$escapedTitle'
      Phase = '$Phase'; Prerequisites = @($quotedPrerequisites); Diagram = '$Diagram'; CostTier = '$CostTier'; DeploymentMode = '$DeploymentMode'
      Navigation = @{ Previous = '$($LastLesson.Id)'; Next = `$null }
    }
"@
$catalogEndPattern = '(?ms)^  \)\s*\}\s*$'

if ([regex]::Matches($catalogText, $catalogEndPattern).Count -ne 1) {
  throw 'Could not identify the end of curriculum/lessons.psd1.'
}

$updatedCatalog = [regex]::Replace(
  $catalogText,
  $catalogEndPattern,
  $catalogEntry + "  )`n}`n",
  1
)

$readme = @"
# $Id - $Title

![Architecture diagram](../assets/diagrams/$Diagram)

## Goal

Describe the learner outcome and the smallest useful Azure or local result for this lesson.

## Prerequisites

- Complete $($Prerequisites -join ', ').
- Review the planned resources and confirm the intended Azure subscription before deployment.

## Architecture

Explain the data flow, trust boundaries, and why each component exists.

## Resources And Cost

Cost tier: **$CostTier**. List every billable resource and the principal cost drivers here.

## Inputs

| Input | Required change |
|---|---|
| ``subscription_id`` | Set explicitly for Azure plans; leave ``null`` only for credential-free work. |
| ``environment`` | Keep ``dev`` for the lab unless testing another naming boundary. |
| ``location`` | Choose a region with the required services and quota. |
| ``name_prefix`` | Use a short lowercase prefix. |

Add only inputs that this lesson actually consumes.

## Deploy

From this folder in PowerShell:

``````powershell
Copy-Item terraform.tfvars.example terraform.tfvars
`$subscriptionId = az account show --query id -o tsv
terraform init -lockfile=readonly
terraform fmt -check
terraform validate
terraform plan -var "subscription_id=`$subscriptionId" -out tfplan
terraform apply tfplan
``````

## Validate

Add lesson-specific commands and state the expected result for each command.

## Troubleshooting

Document the likely permission, quota, naming, networking, and provider errors for this lesson.

## Cleanup

``````powershell
terraform destroy -var "subscription_id=`$subscriptionId"
terraform state list
``````

The destroy should complete and ``terraform state list`` should return no managed resources.

## Production Delta

State what must change before using this pattern in a production environment.

## Exercises

1. Change one safe input and explain the plan difference.
2. Add one validation that proves the lesson outcome without using the Azure portal.

## Navigation

<!-- lesson-navigation:start -->
[Curriculum](../README.md#curriculum)
<!-- lesson-navigation:end -->
"@

$versions = @'
terraform {
  required_version = "~> 1.15.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
'@

$providers = @'
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
'@

$variables = @'
variable "subscription_id" {
  description = "Azure subscription ID. Set explicitly for Azure plan, apply, and destroy operations."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be null or a valid Azure subscription GUID."
  }
}

variable "environment" {
  description = "Short environment name used in resource names and tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Use dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for the lesson."
  type        = string
  default     = "eastus2"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as eastus2."
  }
}

variable "name_prefix" {
  description = "Short lowercase prefix used in resource names."
  type        = string
  default     = "clz"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.name_prefix))
    error_message = "name_prefix must be 2 to 8 lowercase letters or numbers and start with a letter."
  }
}
'@

$locals = @"
locals {
  lesson_id = "$Id"
  name_root = "`${var.name_prefix}-`${var.environment}-$($Id.ToLowerInvariant().Replace('-', ''))"
}
"@

$main = @'
# Add only the resources needed to teach this lesson.
'@

$outputs = @'
output "lesson_contract" {
  description = "Credential-free preview proving that the generated lesson inputs and fixed ID are wired."
  value = {
    lesson_id = local.lesson_id
    name_root = local.name_root
    location  = var.location
  }
}
'@

$tfvars = @'
# Copy this file to terraform.tfvars. Keep real values out of version control.
subscription_id = null
environment     = "dev"
location        = "eastus2"
name_prefix     = "clz"
'@

if ($PSCmdlet.ShouldProcess($Folder, 'Create one lesson and register it in the curriculum')) {
  New-Item -ItemType Directory -Path $LessonPath | Out-Null

  $files = @{
    'README.md'                 = $readme
    'versions.tf'               = $versions
    'providers.tf'              = $providers
    'variables.tf'              = $variables
    'locals.tf'                 = $locals
    'main.tf'                   = $main
    'outputs.tf'                = $outputs
    'terraform.tfvars.example'  = $tfvars
  }

  foreach ($fileName in $files.Keys) {
    $content = $files[$fileName].TrimEnd() + "`n"
    Set-Content -LiteralPath (Join-Path $LessonPath $fileName) -Value $content -Encoding utf8 -NoNewline
  }

  Push-Location $LessonPath
  try {
    & terraform fmt -no-color
    if ($LASTEXITCODE -ne 0) {
      throw "Terraform formatting failed for $Folder."
    }

    & terraform providers lock -platform=windows_amd64 -platform=linux_amd64 -no-color
    if ($LASTEXITCODE -ne 0) {
      throw "Provider lock generation failed for $Folder."
    }

    & terraform init -backend=false -input=false -lockfile=readonly -no-color
    if ($LASTEXITCODE -ne 0) {
      throw "Readonly initialization failed for $Folder."
    }

    & terraform validate -no-color
    if ($LASTEXITCODE -ne 0) {
      throw "Terraform validation failed for $Folder."
    }

    & tflint --init --config (Join-Path $Root '.tflint.hcl')
    if ($LASTEXITCODE -ne 0) {
      throw "TFLint plugin initialization failed for $Folder."
    }

    & tflint --config (Join-Path $Root '.tflint.hcl') --minimum-failure-severity=warning --format compact
    if ($LASTEXITCODE -ne 0) {
      throw "TFLint validation failed for $Folder."
    }
  }
  catch {
    Pop-Location
    Remove-Item -LiteralPath $LessonPath -Recurse -Force
    throw
  }
  Pop-Location

  try {
    Set-Content -LiteralPath $CatalogPath -Value $updatedCatalog -Encoding utf8 -NoNewline
    & (Join-Path $PSScriptRoot 'Sync-AzureFromZeroToHeroCurriculum.ps1') -Write
    & (Join-Path $PSScriptRoot 'Sync-AzureFromZeroToHeroCurriculum.ps1') -Check
    & (Join-Path $PSScriptRoot 'Test-AzureFromZeroToHeroDocs.ps1')

    Import-Module Pester -RequiredVersion $ToolManifest.PowerShellModules.Pester -Force
    $pesterResult = Invoke-Pester -Path (Join-Path $Root 'tests') -PassThru -Output None
    if ($pesterResult.FailedCount -gt 0) {
      throw "$($pesterResult.FailedCount) repository Pester test(s) failed after generating $Folder."
    }
  }
  catch {
    Set-Content -LiteralPath $CatalogPath -Value $originalCatalogText -Encoding utf8 -NoNewline
    Set-Content -LiteralPath $rootReadmePath -Value $originalRootReadme -Encoding utf8 -NoNewline
    Set-Content -LiteralPath $lastReadmePath -Value $originalLastReadme -Encoding utf8 -NoNewline
    if (Test-Path -LiteralPath $LessonPath) {
      Remove-Item -LiteralPath $LessonPath -Recurse -Force
    }
    throw
  }

  Write-Host "Created $Folder and registered $Id in curriculum/lessons.psd1."
}
