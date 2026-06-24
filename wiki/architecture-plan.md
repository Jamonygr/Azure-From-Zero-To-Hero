# Azure From Zero To Hero Architecture Plan

This plan describes how the repository is organized today and how improvements should preserve the learning path while strengthening quality, security, and validation.

## Current Architecture

Azure From Zero To Hero is a folder-per-lesson Terraform curriculum. Each `CLZ-*` folder is independently deployable, has its own provider configuration, variables, outputs, example values, and README, and uses the root scripts for validation.

| Layer | Current role |
|---|---|
| Root README and book PDF | Entry point for learners and the free companion book |
| `CLZ-*` lesson folders | Hands-on Terraform labs in curriculum order |
| `modules/` | Small reusable modules introduced late in the path |
| `scripts/` | Windows/PowerShell validation and setup helpers |
| `.github/workflows/` | Validation-only CI for Terraform and repository quality |
| `wiki/` | Reference material for concepts, security, state, tooling, and troubleshooting |

## Target Architecture

The target architecture keeps early lessons explicit so beginners can see every resource relationship. Reuse increases only after the learner has seen the pattern directly.

| Curriculum phase | Architecture intent |
|---|---|
| CLZ-090 to CLZ-160 | Tooling, Terraform workflow, variables, tags, and state basics stay direct and readable |
| CLZ-170 to CLZ-250 | Network, NSG, Windows VM, IIS, Bastion, Load Balancer, `count`, and `for_each` stay mostly explicit |
| CLZ-260 to CLZ-270 | VMSS and Load Balancer patterns can use `modules/windows-iis-vmss` while lesson-specific scaling logic remains visible |
| CLZ-280 to CLZ-380 | Platform services stay direct unless a repeated pattern becomes distracting |
| CLZ-390 | Capstone composes stable modules and final reference architecture resources |

Module boundaries should stay small. A module is acceptable only when it removes repeated infrastructure code without hiding the concept being taught in that lesson.

## Validation Architecture

The repository has two validation paths:

| Path | Purpose |
|---|---|
| Local script | `scripts/Test-AzureFromZeroToHeroTerraform.ps1` runs format, validate, optional safe plans, and JSON report output |
| CI workflow | `.github/workflows/terraform-validate.yml` runs Terraform validation and repository quality checks on pull requests and `main` |

The default CI path remains validation-only and does not require Azure apply credentials. Optional safe plan checks are available for manual workflow runs and local checks when Azure CLI authentication is available.

Safe plan checks exclude lessons that depend on owned public DNS or an existing remote-state backend. Those lessons should be validated with targeted local context instead of generic CI assumptions.

## Security Architecture

Security is taught as a progression:

| Stage | Pattern |
|---|---|
| Early Windows lessons | Direct access is temporary and scoped with `admin_cidr` |
| Bastion lesson and later | RDP moves to private management through Azure Bastion |
| Key Vault lesson | Generated credentials move into central secret storage |
| Private endpoint lessons | Storage and SQL move away from public service access |
| CI | Validation-only workflow avoids apply credentials by default |

Direct RDP examples exist to teach the resource model. They are not the mature end state. The preferred final pattern is private administration through Bastion, private endpoints for data services, narrow input values, protected Terraform state, and cleanup after every lab.

## Reproducibility Architecture

Each lesson should remain independently runnable from its own folder. Runtime Terraform files stay local and ignored:

| File or folder | Policy |
|---|---|
| `.terraform/` | Generated locally or in CI, not committed |
| `.terraform.lock.hcl` | Generated per lesson, not committed in this curriculum repo |
| `terraform.tfvars` | Local-only user values, not committed |
| `terraform.tfvars.example` | Safe committed defaults |
| `*.tfplan` and state files | Local runtime data, not committed |

This keeps the repository clean for learners while allowing CI and local runs to reinitialize each lesson as needed.

## Learner Flow

1. Read the free companion book for the conceptual path.
2. Start at the root README and confirm workstation readiness.
3. Run lessons in CLZ order.
4. Review each lesson README, variables, and plan before apply.
5. Capture outputs only when needed for validation or the next lesson.
6. Destroy lab resources after validation.
7. Use the wiki pages for deeper reference and troubleshooting.

The architecture goal is not maximum abstraction. The goal is a repeatable Windows-first Azure Terraform learning path that becomes more modular, private, and operationally disciplined as the learner advances.

For the capstone deployment design, see the [Final Reference Architecture Plan](final-reference-architecture-plan.md).
