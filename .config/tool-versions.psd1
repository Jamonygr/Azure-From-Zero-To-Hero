@{
  SchemaVersion = 1

  Runtime = @{
    Terraform       = "1.15.8"
    PowerShell      = "7.6.3"
    AzureCli        = "2.88.0"
    Git             = "2.55.0"
    NodeMajor       = "24"
    NodeMinimum     = "24.18.0"
    TFLint          = "0.63.1"
    Trivy           = "0.72.0"
    Actionlint      = "1.7.12"
    MarkdownLintCli = "0.22.1"
  }

  PowerShellModules = @{
    PSScriptAnalyzer = "1.25.0"
    Pester           = "5.7.1"
  }

  WingetPackages = @{
    pwsh   = "Microsoft.PowerShell"
    az     = "Microsoft.AzureCLI"
    git    = "Git.Git"
    code   = "Microsoft.VisualStudioCode"
    node   = "OpenJS.NodeJS.LTS"
    tflint = "TerraformLinters.tflint"
  }

  VerifiedDownloads = @{
    terraform = @{
      Uri        = "https://releases.hashicorp.com/terraform/1.15.8/terraform_1.15.8_windows_amd64.zip"
      Sha256     = "2ff41d2129afb1982733c132c61a8d6ef038f879f3aeede7fc28b8b8b24acf02"
      Executable = "terraform.exe"
    }
    actionlint = @{
      Uri        = "https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_windows_amd64.zip"
      Sha256     = "6e7241b51e6817ea6a047693d8e6fed13b31819c9a0dd6c5a726e1592d22f6e9"
      Executable = "actionlint.exe"
    }
    trivy = @{
      Uri        = "https://github.com/aquasecurity/trivy/releases/download/v0.72.0/trivy_0.72.0_windows-64bit.zip"
      Sha256     = "ed3cf122060f61818fe1f735fd97557954e16e10bc8b058af9852271cf2e91b3"
      Executable = "trivy.exe"
    }
  }

  LearnerCommands = @("pwsh", "terraform", "az", "git", "code")
  ContributorCommands = @("pwsh", "terraform", "az", "git", "code", "node", "npm", "tflint", "trivy", "actionlint")

  VSCodeExtensions = @(
    "hashicorp.terraform",
    "ms-vscode.powershell",
    "ms-azuretools.vscode-azureresourcegroups",
    "github.vscode-github-actions",
    "DavidAnson.vscode-markdownlint",
    "yzhang.markdown-all-in-one"
  )
}
