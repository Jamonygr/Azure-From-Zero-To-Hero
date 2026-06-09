param(
  [Parameter(Mandatory = $true)][string]$LabFolder
)

$ErrorActionPreference = "Stop"

$target = Resolve-Path $LabFolder
Push-Location $target
try {
  terraform destroy
}
finally {
  Pop-Location
}

