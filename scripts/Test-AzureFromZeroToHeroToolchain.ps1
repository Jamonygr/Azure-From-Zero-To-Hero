[CmdletBinding()]
param(
  [Alias("Profile")]
  [ValidateSet("Learner", "Contributor")]
  [string]$ToolProfile = "Learner"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $repoRoot ".config\tool-versions.psd1"
$manifest = Import-PowerShellDataFile -Path $manifestPath
$requiredCommands = if ($ToolProfile -eq "Contributor") {
  @($manifest.ContributorCommands)
}
else {
  @($manifest.LearnerCommands)
}

$minimumVersions = @{
  pwsh       = [version]$manifest.Runtime.PowerShell
  terraform  = [version]$manifest.Runtime.Terraform
  az         = [version]$manifest.Runtime.AzureCli
  git        = [version]$manifest.Runtime.Git
  node       = [version]$manifest.Runtime.NodeMinimum
  tflint     = [version]$manifest.Runtime.TFLint
  trivy      = [version]$manifest.Runtime.Trivy
  actionlint = [version]$manifest.Runtime.Actionlint
}

function Get-InstalledVersion {
  param([Parameter(Mandatory)][string]$Command)

  $rawVersion = switch ($Command) {
    "pwsh" { (& pwsh --version | Select-Object -First 1) }
    "terraform" {
      $terraformJson = & terraform version -json | ConvertFrom-Json
      $terraformJson.terraform_version
    }
    "az" {
      $azureVersions = & az version --output json | ConvertFrom-Json
      $azureVersions."azure-cli"
    }
    "git" { (& git --version | Select-Object -First 1) }
    "code" { (& code --version | Select-Object -First 1) }
    "node" { (& node --version | Select-Object -First 1) }
    "npm" { (& npm --version | Select-Object -First 1) }
    "tflint" { (& tflint --version | Select-Object -First 1) }
    "trivy" { (& trivy --version | Select-Object -First 1) }
    "actionlint" { (& actionlint -version | Select-Object -First 1) }
    default { $null }
  }

  if (-not $rawVersion) {
    return $null
  }

  $versionMatch = [regex]::Match([string]$rawVersion, '\d+(?:\.\d+){1,3}')
  if (-not $versionMatch.Success) {
    return $null
  }

  return [version]$versionMatch.Value
}

$issues = [System.Collections.Generic.List[string]]::new()
Write-Host "Azure From Zero To Hero $ToolProfile toolchain audit"

foreach ($commandName in $requiredCommands) {
  $commandInfo = Get-Command $commandName -ErrorAction SilentlyContinue
  if (-not $commandInfo) {
    $issues.Add("$commandName is not installed or not available on PATH.")
    Write-Host "[ERROR] $commandName not found"
    continue
  }

  $installedVersion = Get-InstalledVersion -Command $commandName
  if ($installedVersion) {
    Write-Host "[OK] $commandName $installedVersion"
  }
  else {
    Write-Host "[OK] $commandName found at $($commandInfo.Source)"
  }

  if ($minimumVersions.ContainsKey($commandName) -and $installedVersion -and $installedVersion -lt $minimumVersions[$commandName]) {
    $issues.Add("$commandName $installedVersion is older than the supported minimum $($minimumVersions[$commandName]).")
    Write-Host "[ERROR] Upgrade $commandName to $($minimumVersions[$commandName]) or newer."
  }

  if ($commandName -eq "terraform" -and $installedVersion -and $installedVersion -ne [version]$manifest.Runtime.Terraform) {
    $issues.Add("Terraform $installedVersion does not match the repository-tested version $($manifest.Runtime.Terraform).")
    Write-Host "[ERROR] Use the repository-tested Terraform version $($manifest.Runtime.Terraform)."
  }

  if ($commandName -eq "node" -and $installedVersion -and $installedVersion.Major -ne [int]$manifest.Runtime.NodeMajor) {
    $issues.Add("Node.js major version $($installedVersion.Major) does not match supported major $($manifest.Runtime.NodeMajor).")
    Write-Host "[ERROR] Use Node.js major $($manifest.Runtime.NodeMajor)."
  }
}

if ($ToolProfile -eq "Contributor") {
  foreach ($moduleName in $manifest.PowerShellModules.Keys) {
    $requiredVersion = [version]$manifest.PowerShellModules[$moduleName]
    $installedModule = Get-Module -ListAvailable -Name $moduleName |
      Sort-Object Version -Descending |
      Select-Object -First 1

    if (-not $installedModule -or $installedModule.Version -lt $requiredVersion) {
      $current = if ($installedModule) { $installedModule.Version } else { "missing" }
      $issues.Add("PowerShell module $moduleName is $current; $requiredVersion or newer is required.")
      Write-Host "[ERROR] $moduleName $current (requires $requiredVersion or newer)"
    }
    else {
      Write-Host "[OK] $moduleName $($installedModule.Version)"
    }
  }

  if (Get-Command code -ErrorAction SilentlyContinue) {
    $installedExtensions = @(code --list-extensions 2>$null)
    foreach ($extension in $manifest.VSCodeExtensions) {
      if ($installedExtensions -contains $extension) {
        Write-Host "[OK] VS Code extension $extension"
      }
      else {
        $issues.Add("VS Code extension $extension is not installed.")
        Write-Host "[ERROR] VS Code extension missing: $extension"
      }
    }
  }
}

try {
  $signedInAccountId = & az account show --query id --output tsv 2>$null
  if ($signedInAccountId) {
    Write-Host "[OK] Azure CLI has an active account (details masked)."
  }
  else {
    Write-Host "[WARN] Azure CLI is not signed in. Run az login before Azure resource labs."
  }
}
catch {
  Write-Host "[WARN] Azure CLI is not signed in. Run az login before Azure resource labs."
}

if ($issues.Count -gt 0) {
  throw "$($issues.Count) $ToolProfile toolchain requirement(s) are not satisfied.`n$($issues -join "`n")"
}

Write-Host "Azure From Zero To Hero $ToolProfile toolchain audit passed."
