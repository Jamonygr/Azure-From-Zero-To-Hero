param()

$ErrorActionPreference = "Stop"

$commands = @(
  @{ Name = "pwsh"; VersionArgs = @("--version"); Required = $true },
  @{ Name = "terraform"; VersionArgs = @("version"); Required = $true },
  @{ Name = "az"; VersionArgs = @("version"); Required = $true },
  @{ Name = "git"; VersionArgs = @("--version"); Required = $true },
  @{ Name = "code"; VersionArgs = @("--version"); Required = $true },
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

try {
  $account = az account show --output json 2>$null | ConvertFrom-Json
  Write-Host "[OK] Azure CLI account: $($account.name) / $($account.id)"
}
catch {
  Write-Host "[WARN] Azure CLI is not signed in. Run az login before Azure resource labs."
}

if ($failed) {
  throw "Required Chriz Labz workstation tools are missing."
}

Write-Host "Chriz Labz workstation toolchain check completed."
