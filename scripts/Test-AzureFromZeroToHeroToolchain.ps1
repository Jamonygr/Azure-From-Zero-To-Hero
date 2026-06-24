param()

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..")
$workspaceExtensionsPath = Join-Path $repoRoot ".vscode\extensions.json"

$commands = @(
  @{ Name = "pwsh"; VersionArgs = @("--version"); Required = $true },
  @{ Name = "terraform"; VersionArgs = @("version"); Required = $true },
  @{ Name = "az"; VersionArgs = @("version"); Required = $true },
  @{ Name = "git"; VersionArgs = @("--version"); Required = $true },
  @{ Name = "code"; VersionArgs = @("--version"); Required = $true },
  @{ Name = "node"; VersionArgs = @("--version"); Required = $false },
  @{ Name = "npm"; VersionArgs = @("--version"); Required = $false },
  @{ Name = "tflint"; VersionArgs = @("--version"); Required = $false },
  @{ Name = "trivy"; VersionArgs = @("--version"); Required = $false },
  @{ Name = "winget"; VersionArgs = @("--version"); Required = $false }
)

$failed = $false

foreach ($item in $commands) {
  $cmd = Get-Command $item.Name -ErrorAction SilentlyContinue
  if (-not $cmd) {
    $level = if ($item.Required) { "ERROR" } else { "WARN" }
    Write-Host "[$level] $($item.Name) was not found on PATH."
    if ($item.Required) {
      $failed = $true
    }
    continue
  }

  Write-Host "[OK] $($item.Name) found at $($cmd.Source)"
  try {
    & $item.Name @($item.VersionArgs) | Select-Object -First 6
  }
  catch {
    Write-Host "[WARN] Could not read version for $($item.Name): $($_.Exception.Message)"
  }
}

$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
  $extensions = @(
    "hashicorp.terraform",
    "ms-vscode.powershell",
    "ms-azuretools.vscode-azureresourcegroups",
    "github.vscode-github-actions",
    "yzhang.markdown-all-in-one"
  )

  if (Test-Path $workspaceExtensionsPath) {
    try {
      $extensionConfig = Get-Content -Raw $workspaceExtensionsPath | ConvertFrom-Json
      $extensions = @($extensionConfig.recommendations)
    }
    catch {
      Write-Host "[WARN] Could not read VS Code workspace recommendations: $($_.Exception.Message)"
    }
  }

  $installed = @()
  try {
    $installed = @(code --list-extensions)
  }
  catch {
    Write-Host "[WARN] Could not list VS Code extensions: $($_.Exception.Message)"
  }

  foreach ($extension in $extensions) {
    if ($installed -contains $extension) {
      Write-Host "[OK] VS Code extension installed: $extension"
    }
    else {
      Write-Host "[WARN] VS Code extension missing: $extension"
    }
  }
}

$psScriptAnalyzer = Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if ($psScriptAnalyzer) {
  Write-Host "[OK] PSScriptAnalyzer module installed: $($psScriptAnalyzer.Version)"
}
else {
  Write-Host "[WARN] PSScriptAnalyzer module missing. Install with: Install-Module PSScriptAnalyzer -Scope CurrentUser"
}

try {
  $account = az account show --output json 2>$null | ConvertFrom-Json
  Write-Host "[OK] Azure CLI account: $($account.name) / $($account.id)"
}
catch {
  Write-Host "[WARN] Azure CLI is not signed in. Run az login before Azure resource labs."
}

if ($failed) {
  throw "Required Azure From Zero To Hero workstation tools are missing."
}

Write-Host "Azure From Zero To Hero workstation toolchain check completed."
