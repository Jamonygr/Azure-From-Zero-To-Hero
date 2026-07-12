BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  $script:ManifestPath = Join-Path $script:RepoRoot "curriculum\lessons.psd1"
}

Describe "Curriculum manifest" {
  It "loads as PowerShell data" {
    Test-Path -LiteralPath $script:ManifestPath | Should -BeTrue
    { Import-PowerShellDataFile -Path $script:ManifestPath } | Should -Not -Throw
  }

  It "contains one unique entry for every lesson directory" {
    $manifest = Import-PowerShellDataFile -Path $script:ManifestPath
    $lessonFolders = @(Get-ChildItem -Path $script:RepoRoot -Directory -Filter "CLZ-*" | Sort-Object Name)
    $entries = @($manifest.Lessons)

    $entries.Count | Should -Be $lessonFolders.Count
    @($entries.Id | Select-Object -Unique).Count | Should -Be $entries.Count
    @($entries.Folder | Select-Object -Unique).Count | Should -Be $entries.Count

    foreach ($folder in $lessonFolders) {
      $entries.Folder | Should -Contain $folder.Name
    }
  }

  It "defines the fields required by documentation tooling" {
    $manifest = Import-PowerShellDataFile -Path $script:ManifestPath
    foreach ($lesson in $manifest.Lessons) {
      foreach ($property in @("Id", "Folder", "Title", "Phase", "Prerequisites", "Diagram", "CostTier", "DeploymentMode")) {
        $lesson.ContainsKey($property) | Should -BeTrue -Because "$($lesson.Id) requires $property"
      }
    }
  }
}

Describe "Pinned tool policy" {
  BeforeAll {
    $script:ToolManifest = Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot ".config\tool-versions.psd1")
  }

  It "keeps Terraform constraints on the tested minor line" {
    $expectedConstraint = "~> $(([version]$script:ToolManifest.Runtime.Terraform).Major).$(([version]$script:ToolManifest.Runtime.Terraform).Minor).0"
    $versionFiles = Get-ChildItem -Path $script:RepoRoot -Recurse -File -Filter "versions.tf" |
      Where-Object { $_.FullName -notmatch '\\.terraform\\' }

    foreach ($file in $versionFiles) {
      (Get-Content -Raw -LiteralPath $file.FullName) | Should -Match ([regex]::Escape("required_version = `"$expectedConstraint`""))
    }
  }

  It "keeps CI and lesson examples on the manifest Terraform version" {
    $version = $script:ToolManifest.Runtime.Terraform
    $rootWorkflow = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot ".github\workflows\terraform-validate.yml")
    $validateExample = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot "CLZ-370-github-actions-terraform\.github\workflows\terraform-validate.yml.example")
    $planExample = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot "CLZ-370-github-actions-terraform\.github\workflows\terraform-plan-oidc.yml.example")

    $rootWorkflow | Should -Match ([regex]::Escape("TERRAFORM_VERSION: $version"))
    $validateExample | Should -Match ([regex]::Escape("terraform_version: $version"))
    $planExample | Should -Match ([regex]::Escape("terraform_version: $version"))
  }

  It "pins every third-party action in the root workflow to a full commit SHA" {
    $workflow = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot ".github\workflows\terraform-validate.yml")
    $actionReferences = [regex]::Matches($workflow, '(?m)^\s*uses:\s+[^@\s]+@([^\s#]+)')
    $actionReferences.Count | Should -BeGreaterThan 0
    foreach ($reference in $actionReferences) {
      $reference.Groups[1].Value | Should -Match '^[0-9a-f]{40}$'
    }
  }
}

Describe "Terraform reproducibility and mock tests" {
  BeforeAll {
    $script:RequiredTerraformTestFiles = @(
      "modules\network-core\tests\network-core.tftest.hcl",
      "modules\windows-iis-vmss\tests\windows-iis-vmss.tftest.hcl",
      "CLZ-180-network-security-groups\tests\input-contracts.tftest.hcl",
      "CLZ-270-windows-vmss-autoscaling\tests\input-contracts.tftest.hcl",
      "CLZ-300-public-dns-optional\tests\input-contracts.tftest.hcl",
      "CLZ-320-cross-environment-state\tests\input-contracts.tftest.hcl"
    )
    $script:TerraformTestFiles = @(
      Get-ChildItem -Path $script:RepoRoot -Recurse -File -Filter "*.tftest.hcl" |
        Where-Object { $_.FullName -notmatch '\\.terraform\\' } |
        ForEach-Object { [System.IO.Path]::GetRelativePath($script:RepoRoot, $_.FullName) }
    )
  }

  It "commits a dependency lock for every lesson and tested module root" {
    $terraformRoots = @(
      Get-ChildItem -Path $script:RepoRoot -Directory -Filter "CLZ-*"
      Get-ChildItem -Path (Join-Path $script:RepoRoot "modules") -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "versions.tf") }
    )

    foreach ($root in $terraformRoots) {
      $lockPath = Join-Path $root.FullName ".terraform.lock.hcl"
      Test-Path -LiteralPath $lockPath -PathType Leaf | Should -BeTrue -Because "$($root.Name) is a Terraform root"
      $versionsPath = Join-Path $root.FullName "versions.tf"
      if ((Get-Content -Raw -LiteralPath $versionsPath) -match 'required_providers') {
        (Get-Content -Raw -LiteralPath $lockPath) | Should -Match 'h1:'
      }
    }
  }

  It "keeps every Terraform test credential-free and plan-only" {
    foreach ($requiredPath in $script:RequiredTerraformTestFiles) {
      $script:TerraformTestFiles | Should -Contain $requiredPath
    }

    foreach ($relativePath in $script:TerraformTestFiles) {
      $path = Join-Path $script:RepoRoot $relativePath
      Test-Path -LiteralPath $path -PathType Leaf | Should -BeTrue
      $content = Get-Content -Raw -LiteralPath $path
      $content | Should -Match 'mock_provider\s+"azurerm"'
      $runCount = [regex]::Matches($content, '(?m)^run\s+"').Count
      $planCount = [regex]::Matches($content, '(?m)^\s*command\s*=\s*plan\s*$').Count
      $runCount | Should -BeGreaterThan 0
      $planCount | Should -Be $runCount -Because "$relativePath must never use the default apply test command"
    }
  }

  It "runs Terraform tests from the aggregate quality gate" {
    $qualityScript = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot "scripts\Test-AzureFromZeroToHeroQuality.ps1")
    $terraformScript = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot "scripts\Test-AzureFromZeroToHeroTerraform.ps1")
    $qualityScript | Should -Match '(?m)^\s*-Test\s+`'
    $terraformScript | Should -Match 'terraform.+test|"test"'
  }
}

Describe "Lesson documentation" {
  BeforeAll {
    $script:RequiredHeadings = @(
      "## Goal",
      "## Prerequisites",
      "## Architecture",
      "## Resources And Cost",
      "## Inputs",
      "## Deploy",
      "## Validate",
      "## Troubleshooting",
      "## Cleanup",
      "## Production Delta",
      "## Exercises",
      "## Navigation"
    )
  }

  It "contains all required sections and linked navigation in <Name>" -ForEach @(
    Get-ChildItem -Path $script:RepoRoot -Directory -Filter "CLZ-*" |
      ForEach-Object { @{ Name = $_.Name; Readme = Join-Path $_.FullName "README.md" } }
  ) {
    Test-Path -LiteralPath $Readme | Should -BeTrue
    $content = Get-Content -Raw -LiteralPath $Readme
    foreach ($heading in $script:RequiredHeadings) {
      $content | Should -Match ([regex]::Escape($heading))
    }

    $navigation = ($content -split "## Navigation", 2)[1]
    $navigation | Should -Match '\[[^\]]+\]\([^\)]+README\.md\)'
  }
}

Describe "Terraform lesson inputs" {
  It "does not declare variables unused outside variables.tf in <Name>" -ForEach @(
    Get-ChildItem -Path $script:RepoRoot -Directory -Filter "CLZ-*" |
      ForEach-Object { @{ Name = $_.Name; Folder = $_.FullName } }
  ) {
    $variableFile = Join-Path $Folder "variables.tf"
    if (-not (Test-Path -LiteralPath $variableFile)) {
      return
    }

    $declared = @(
      [regex]::Matches((Get-Content -Raw -LiteralPath $variableFile), 'variable\s+"([^"]+)"') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
    )
    $otherTerraform = @(
      Get-ChildItem -Path $Folder -File -Filter "*.tf" |
        Where-Object Name -ne "variables.tf" |
        ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }
    ) -join "`n"
    $referenced = @(
      [regex]::Matches($otherTerraform, 'var\.([A-Za-z0-9_]+)') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
    )

    $unused = @($declared | Where-Object { $_ -notin $referenced })
    $unused | Should -BeNullOrEmpty
  }

  It "keeps each tfvars example aligned with declared variables in <Name>" -ForEach @(
    Get-ChildItem -Path $script:RepoRoot -Directory -Filter "CLZ-*" |
      ForEach-Object { @{ Name = $_.Name; Folder = $_.FullName } }
  ) {
    $examplePath = Join-Path $Folder "terraform.tfvars.example"
    $variablePath = Join-Path $Folder "variables.tf"
    if (-not (Test-Path -LiteralPath $examplePath) -or -not (Test-Path -LiteralPath $variablePath)) {
      return
    }

    $declared = @(
      [regex]::Matches((Get-Content -Raw -LiteralPath $variablePath), 'variable\s+"([^"]+)"') |
        ForEach-Object { $_.Groups[1].Value }
    )
    $exampleVariables = @(
      [regex]::Matches((Get-Content -Raw -LiteralPath $examplePath), '(?m)^([A-Za-z][A-Za-z0-9_]*)\s*=') |
        ForEach-Object { $_.Groups[1].Value }
    )

    foreach ($name in $exampleVariables) {
      $declared | Should -Contain $name
    }
  }
}

Describe "Repository safety and drift" {
  It "denies unmatched RDP before Azure default NSG rules" {
    $rdpPolicyFiles = @(
      "CLZ-180-network-security-groups\security.tf",
      "CLZ-190-windows-vm-basics\compute-windows.tf",
      "CLZ-200-windows-vm-iis-bootstrap\compute-windows.tf",
      "CLZ-210-azure-bastion-rdp\bastion.tf",
      "CLZ-230-load-balancer-nat-rules\load-balancer-nat.tf",
      "CLZ-240-count-windows-vms\compute-count.tf",
      "CLZ-250-for-each-windows-vms\compute-for-each.tf",
      "CLZ-390-final-windows-reference-architecture\capstone.tf"
    )

    foreach ($relativePath in $rdpPolicyFiles) {
      $content = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot $relativePath)
      $content | Should -Match '(?s)(deny_other_rdp|DenyOtherRdp).*?priority\s*=\s*120.*?access\s*=\s*"Deny".*?destination_port_range\s*=\s*"3389"'
    }
  }

  It "contains no stale legacy lab path in editable text" {
    $extensions = @("*.md", "*.ps1", "*.psd1", "*.tf", "*.tfvars", "*.hcl", "*.yml", "*.yaml", "*.json", "*.jsonc")
    $files = foreach ($extension in $extensions) {
      Get-ChildItem -Path $script:RepoRoot -Recurse -File -Filter $extension |
        Where-Object { $_.FullName -notmatch '\\.terraform\\|\\artifacts\\' }
    }
    $legacyPath = "Chriz" + " Labz"
    $stale = @($files | Select-String -SimpleMatch $legacyPath)
    $stale | Should -BeNullOrEmpty
  }

  It "does not print Azure subscription names or identifiers" {
    $toolchain = Get-Content -Raw -LiteralPath (Join-Path $script:RepoRoot "scripts\Test-AzureFromZeroToHeroToolchain.ps1")
    $toolchain | Should -Not -Match '\$account\.(name|id)'
    $toolchain | Should -Not -Match 'Azure CLI account:'
    $toolchain | Should -Match 'details masked'
  }

  It "keeps generated curriculum sections synchronized" {
    & (Join-Path $script:RepoRoot "scripts\Sync-AzureFromZeroToHeroCurriculum.ps1") -Check
    $LASTEXITCODE | Should -BeIn @(0, $null)
  }
}
