param()

$ErrorActionPreference = "Stop"

$tools = @("terraform", "az", "git")
foreach ($tool in $tools) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if (-not $cmd) {
    throw "$tool was not found on PATH."
  }
  Write-Host "$tool found at $($cmd.Source)"
}

terraform version
az version --output table
git --version

