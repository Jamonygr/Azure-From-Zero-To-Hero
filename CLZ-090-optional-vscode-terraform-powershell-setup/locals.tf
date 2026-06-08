locals {
  required_commands = [
    "pwsh",
    "terraform",
    "az",
    "git",
    "code"
  ]

  recommended_extensions = [
    "hashicorp.terraform",
    "ms-vscode.powershell",
    "ms-azuretools.vscode-azureresourcegroups",
    "github.vscode-github-actions",
    "yzhang.markdown-all-in-one"
  ]
}
