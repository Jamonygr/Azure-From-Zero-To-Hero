[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$LabFolder,

  [Parameter(Mandatory)]
  [ValidatePattern("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")]
  [string]$SubscriptionId
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$target = (Resolve-Path -LiteralPath $LabFolder).Path
$targetItem = Get-Item -LiteralPath $target
$relativeTarget = [System.IO.Path]::GetRelativePath($repoRoot, $target)

if (-not $targetItem.PSIsContainer -or
  $targetItem.Parent.FullName -ne $repoRoot -or
  $relativeTarget -notmatch '^CLZ-\d{3}-[a-z0-9-]+$') {
  throw "LabFolder must resolve to a top-level CLZ-* lesson inside this repository."
}

if (-not (Test-Path -LiteralPath (Join-Path $target "versions.tf") -PathType Leaf)) {
  throw "The selected lesson is not a Terraform root."
}

foreach ($commandName in @("az", "terraform")) {
  if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
    throw "$commandName is required for cleanup."
  }
}

$activeSubscriptionId = & az account show --query id --output tsv 2>$null
if ($LASTEXITCODE -ne 0 -or -not $activeSubscriptionId) {
  throw "Azure CLI is not signed in. Run az login and select the intended lab subscription."
}

if ($activeSubscriptionId -ne $SubscriptionId) {
  throw "The active Azure CLI account does not match -SubscriptionId. Account details are intentionally masked."
}

Push-Location $target
try {
  $stateAddresses = @(& terraform state list -no-color 2>$null)
  if ($LASTEXITCODE -ne 0) {
    throw "Terraform state could not be read. Initialize the lesson and verify its backend before cleanup."
  }

  if ($stateAddresses.Count -eq 0) {
    Write-Host "No managed resources are present in the selected lesson state. Nothing to destroy."
    return
  }

  if ($PSCmdlet.ShouldProcess($relativeTarget, "run an interactive Terraform destroy against the explicitly verified subscription")) {
    $destroyArguments = @("destroy", "-var", "subscription_id=$SubscriptionId")
    if (-not (Test-Path -LiteralPath (Join-Path $target "terraform.tfvars") -PathType Leaf)) {
      $destroyArguments += "-var-file=terraform.tfvars.example"
    }

    & terraform @destroyArguments
    if ($LASTEXITCODE -ne 0) {
      throw "Terraform destroy failed for the selected lesson."
    }
  }
}
finally {
  Pop-Location
}
