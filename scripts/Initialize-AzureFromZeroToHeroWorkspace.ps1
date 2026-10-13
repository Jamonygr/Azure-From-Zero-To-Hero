[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
param(
  [Alias("Profile")]
  [ValidateSet("Learner", "Contributor")]
  [string]$ToolProfile = "Learner",
  [switch]$Install
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifest = Import-PowerShellDataFile -Path (Join-Path $repoRoot ".config\tool-versions.psd1")

function Install-VerifiedZipTool {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][hashtable]$Definition,
    [Parameter(Mandatory)][string]$Destination
  )

  $temporaryDirectory = Join-Path $env:TEMP "azure-hero-$Name-$([guid]::NewGuid().ToString('N'))"
  $archivePath = Join-Path $temporaryDirectory "$Name.zip"
  $expandedPath = Join-Path $temporaryDirectory "expanded"
  New-Item -ItemType Directory -Force -Path $temporaryDirectory, $expandedPath | Out-Null

  try {
    Invoke-WebRequest -Uri $Definition.Uri -OutFile $archivePath
    $actualHash = (Get-FileHash -Algorithm SHA256 $archivePath).Hash.ToLowerInvariant()
    if ($actualHash -ne $Definition.Sha256) {
      throw "$Name checksum verification failed. Expected $($Definition.Sha256), received $actualHash."
    }

    Expand-Archive -Path $archivePath -DestinationPath $expandedPath -Force
    $sourceExecutable = Join-Path $expandedPath $Definition.Executable
    if (-not (Test-Path -LiteralPath $sourceExecutable -PathType Leaf)) {
      throw "$Name archive does not contain $($Definition.Executable)."
    }

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Copy-Item -LiteralPath $sourceExecutable -Destination (Join-Path $Destination $Definition.Executable) -Force
  }
  finally {
    Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
  }
}

if (-not $Install) {
  & (Join-Path $PSScriptRoot "Test-AzureFromZeroToHeroToolchain.ps1") -ToolProfile $ToolProfile
  return
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
  throw "WinGet is required for -Install. Install or update Microsoft App Installer, then retry."
}

$commandNames = if ($ToolProfile -eq "Contributor") {
  @($manifest.ContributorCommands)
}
else {
  @($manifest.LearnerCommands)
}

foreach ($commandName in $commandNames) {
  if (-not $manifest.WingetPackages.ContainsKey($commandName)) {
    continue
  }

  $packageId = $manifest.WingetPackages[$commandName]
  $installed = Get-Command $commandName -ErrorAction SilentlyContinue
  $verb = if ($installed) { "upgrade" } else { "install" }
  if ($PSCmdlet.ShouldProcess($packageId, "$verb with WinGet")) {
    & winget $verb --id $packageId --exact --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "WinGet could not $verb $packageId. Review the WinGet output and rerun the toolchain audit."
    }
  }
}

$userBin = Join-Path $env:LOCALAPPDATA "AzureFromZeroToHero\bin"
$downloadRequirements = @{
  terraform  = [version]$manifest.Runtime.Terraform
  actionlint = [version]$manifest.Runtime.Actionlint
  trivy      = [version]$manifest.Runtime.Trivy
}

foreach ($commandName in $downloadRequirements.Keys) {
  if ($commandName -notin $commandNames) {
    continue
  }

  $installedVersion = $null
  $commandInfo = Get-Command $commandName -ErrorAction SilentlyContinue
  if ($commandInfo) {
    $versionText = switch ($commandName) {
      "terraform" { (& terraform version -json | ConvertFrom-Json).terraform_version }
      "actionlint" { & actionlint -version | Select-Object -First 1 }
      "trivy" { & trivy --version | Select-Object -First 1 }
    }
    $versionMatch = [regex]::Match([string]$versionText, '\d+(?:\.\d+){1,3}')
    if ($versionMatch.Success) {
      $installedVersion = [version]$versionMatch.Value
    }
  }

  if ($installedVersion -eq $downloadRequirements[$commandName]) {
    continue
  }

  if ($PSCmdlet.ShouldProcess("$commandName $($downloadRequirements[$commandName])", "install verified user-local tool")) {
    Install-VerifiedZipTool -Name $commandName -Definition $manifest.VerifiedDownloads[$commandName] -Destination $userBin
  }
}

if (Test-Path -LiteralPath $userBin) {
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $pathEntries = @($userPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($userBin -notin $pathEntries -and $PSCmdlet.ShouldProcess("User PATH", "prepend $userBin")) {
    [Environment]::SetEnvironmentVariable("Path", (($userBin + ';' + $userPath).TrimEnd(';')), "User")
  }
  if ($env:Path -notlike "$userBin;*") {
    $env:Path = "$userBin;$env:Path"
  }
}

if ($ToolProfile -eq "Contributor") {
  foreach ($moduleName in $manifest.PowerShellModules.Keys) {
    $requiredVersion = $manifest.PowerShellModules[$moduleName]
    if ($PSCmdlet.ShouldProcess("$moduleName $requiredVersion", "install PowerShell module")) {
      Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -Force -AllowClobber
    }
  }

  if (Get-Command code -ErrorAction SilentlyContinue) {
    $installedExtensions = @(code --list-extensions 2>$null)
    foreach ($extension in $manifest.VSCodeExtensions) {
      if ($installedExtensions -contains $extension) {
        continue
      }

      if ($PSCmdlet.ShouldProcess($extension, "install VS Code extension")) {
        & code --install-extension $extension
        if ($LASTEXITCODE -ne 0) {
          throw "VS Code extension installation failed: $extension"
        }
      }
    }
  }
}

Write-Host "Installation pass complete. Open a new terminal if PATH changed, then run:"
Write-Host ".\scripts\Test-AzureFromZeroToHeroToolchain.ps1 -Profile $ToolProfile"
