param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$Validate
)

$ErrorActionPreference = "Stop"

Push-Location $Root
try {
  terraform fmt -check -recursive

  if ($Validate) {
    Get-ChildItem -Directory -Filter "CLZ-*" | ForEach-Object {
      Push-Location $_.FullName
      try {
        terraform init -backend=false -input=false
        terraform validate
      }
      finally {
        Pop-Location
      }
    }
  }
}
finally {
  Pop-Location
}

