param()

$ErrorActionPreference = "Stop"

$tools = @("pwsh", "terraform", "az", "git", "code")
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
pwsh --version
code --version

