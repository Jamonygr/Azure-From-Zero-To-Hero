# CLZ-090 - Optional VS Code Terraform PowerShell Setup

![Windows workstation toolchain](../assets/diagrams/workstation-toolchain.svg)

## Overview

This optional pre-lab prepares a Windows workstation for the Chriz Labz Terraform path. It belongs before `CLZ-100` because a reliable local toolchain prevents avoidable problems later. The lab does not create Azure resources. Instead, it focuses on the editor, terminal, package manager, Terraform CLI, Azure CLI, Git, VS Code extensions, PowerShell profile choices, and repeatable validation commands.

The main curriculum already includes `CLZ-110-windows-workstation-setup`, but this optional lab is intentionally deeper. Use it if you want a stronger setup guide before touching Azure resources, or if your workstation has never been used for Terraform work before.

## What You Build

| Area | Outcome |
|---|---|
| Package install path | A repeatable Windows install approach using WinGet where available |
| Terminal | PowerShell 7 available as the preferred shell |
| Editor | VS Code installed with command-line launch support |
| Terraform | Terraform CLI installed and visible on `PATH` |
| Azure CLI | Azure CLI installed and signed in |
| Git | Git installed for repository work |
| VS Code extensions | Terraform and Azure-focused extensions installed |
| Validation | A local script confirms the toolchain shape |

## Why This Lab Is Optional

Some users already have a working workstation. If `terraform version`, `az version`, `git --version`, `pwsh --version`, and `code --version` all work from PowerShell, you can continue directly to `CLZ-100`. If one of those commands fails, this lab gives you a structured way to fix the environment.

Keeping this lab optional prevents the core curriculum from spending too much time on workstation setup while still giving new users a complete guide.

## Toolchain Architecture

The Chriz Labz workstation has five core tools:

| Tool | Role |
|---|---|
| PowerShell 7 | Primary terminal and automation shell |
| VS Code | Editor for Terraform, Markdown, PowerShell, and YAML |
| Terraform CLI | Plans and applies Azure infrastructure |
| Azure CLI | Authenticates and inspects Azure subscriptions |
| Git | Tracks changes and works with GitHub |

VS Code is not required for Terraform to work, but it makes the lab experience smoother. The integrated terminal lets you read the README, inspect `.tf` files, run PowerShell, and execute Terraform from the same workspace.

## Install Order

Use this order when setting up a new Windows workstation:

1. Confirm WinGet is available.
2. Install PowerShell 7.
3. Install Git.
4. Install VS Code.
5. Install Terraform.
6. Install Azure CLI.
7. Restart PowerShell or Windows Terminal.
8. Confirm every command is on `PATH`.
9. Install VS Code extensions.
10. Sign in to Azure CLI and select the target subscription.

Restarting the terminal matters. Several installers update `PATH`, and existing terminal sessions may not see the change until reopened.

## WinGet Check

WinGet is the Windows Package Manager command-line client. It is available on modern Windows client systems and is the preferred install route for this lab when available.

Run:

~~~powershell
winget --version
~~~

If the command is not found, update App Installer from Microsoft Store or follow the official Windows Package Manager guidance. If WinGet is unavailable because of enterprise policy, use the official MSI installers for the tools instead.

## Install Commands

Run PowerShell as your normal user unless your workstation policy requires elevation. Some installers may prompt for approval.

~~~powershell
winget install --id Microsoft.PowerShell --source winget
winget install --id Git.Git --source winget
winget install --id Microsoft.VisualStudioCode --source winget
winget install --id Hashicorp.Terraform --source winget
winget install --exact --id Microsoft.AzureCLI
~~~

After installation, close and reopen the terminal.

## Version Validation

Run:

~~~powershell
pwsh --version
git --version
code --version
terraform version
az version
~~~

Expected result:

| Command | Expected behavior |
|---|---|
| `pwsh --version` | Prints a PowerShell 7 version |
| `git --version` | Prints a Git version |
| `code --version` | Prints VS Code version details |
| `terraform version` | Prints Terraform CLI version |
| `az version` | Prints Azure CLI version data |

If a command fails, the most likely cause is a missing install or a terminal session that has not picked up the updated `PATH`.

## VS Code Extensions

Install the recommended extensions:

~~~powershell
code --install-extension hashicorp.terraform
code --install-extension ms-vscode.powershell
code --install-extension ms-azuretools.vscode-azureresourcegroups
code --install-extension github.vscode-github-actions
code --install-extension yzhang.markdown-all-in-one
~~~

The Terraform extension helps with syntax and formatting. The PowerShell extension improves script editing. The Azure extension is useful for browsing resources. GitHub Actions support helps with workflow files. Markdown support makes lesson README work easier.

## Open The Repository

From the folder that contains this repository, run:

~~~powershell
code .
~~~

If `code` is not recognized, reopen the terminal. If it still fails, confirm VS Code was installed with command-line support. On Windows installs, the VS Code command should normally be added to `PATH`.

## PowerShell Terminal Profile

Use PowerShell 7 as the default terminal in VS Code when possible. Open the Command Palette and search for terminal profile settings, or use the integrated terminal dropdown to select PowerShell.

Recommended habits:

| Habit | Reason |
|---|---|
| Use PowerShell for lab commands | The docs are written with PowerShell examples |
| Run Terraform from the lesson folder | State and paths stay predictable |
| Keep one terminal per active lesson | Reduces wrong-folder mistakes |
| Use `Get-Location` before apply or destroy | Confirms current folder |

## Azure CLI Sign-In

Run:

~~~powershell
az login
az account show
az account list --output table
~~~

If you have more than one subscription, select the correct one:

~~~powershell
az account set --subscription "<subscription-id-or-name>"
az account show
~~~

Later Terraform lessons can also use `subscription_id` in local `terraform.tfvars` if your environment needs explicit subscription selection.

## Terraform Smoke Test

This optional lab contains a small valid Terraform configuration that creates no Azure resources. It exists so you can test the Terraform command flow safely.

Run from this folder:

~~~powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
~~~

The plan should show no Azure infrastructure resources. Terraform may still display output values because this folder includes validation metadata. That is expected. The goal is to prove the CLI and folder workflow work before the real Azure labs begin.

## Local Toolchain Script

Run the helper:

~~~powershell
..\scripts\Test-ChrizLabzToolchain.ps1
~~~

The script checks common commands, prints installed versions where possible, and warns about missing optional editor extensions. It does not install anything or change Azure resources.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `winget` is not recognized | App Installer missing or blocked | Update App Installer or use official installers |
| `terraform` is not recognized | Terraform not on `PATH` | Reopen terminal or reinstall Terraform |
| `az` is not recognized | Azure CLI install not visible | Reopen terminal or reinstall Azure CLI |
| `code` is not recognized | VS Code command missing from `PATH` | Reopen terminal or repair VS Code install |
| `az login` opens wrong account | Browser session reused | Sign out in browser or use device code flow |
| VS Code terminal opens old shell | Default profile not changed | Select PowerShell profile |

## Validation Checklist

- `pwsh --version` works.
- `terraform version` works.
- `az version` works.
- `git --version` works.
- `code --version` works.
- `az account show` returns the intended subscription.
- VS Code opens the repository.
- Terraform extension is installed.
- PowerShell extension is installed.
- `terraform validate` passes in this folder.

## Related Wiki

Use [Windows Workstation Tooling](../wiki/windows-workstation-tooling.md) when you need a deeper reference for install choices, `PATH` diagnostics, VS Code workspace habits, Azure account hygiene, execution policy, and keeping local Terraform files out of git.

## Cleanup

This lab creates no Azure resources. There is no `terraform destroy` requirement. If you created local files such as `terraform.tfvars`, keep them local and uncommitted.

## Next Lesson

Continue to `CLZ-100-foundations` after the toolchain validates.
