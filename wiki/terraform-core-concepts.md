# Terraform Core Concepts

![Terraform workflow](../assets/diagrams/terraform-workflow.svg)

Terraform is a desired-state workflow. You write the target shape of Azure resources, Terraform compares that configuration with state and provider data, then it proposes changes.

## Command Flow
| Command | Purpose | When to use |
|---|---|---|
| `terraform init` | Downloads providers and prepares the folder | First run and after provider/module/backend changes |
| `terraform fmt -check` | Confirms consistent formatting | Before every commit |
| `terraform validate` | Checks configuration structure | Before planning |
| `terraform plan -out tfplan` | Creates a reviewed execution plan | Before every apply |
| `terraform apply tfplan` | Applies the reviewed plan | Only after plan review |
| `terraform destroy` | Removes resources in this state | End of each lab |

## File Roles
| File | Why it exists |
|---|---|
| `versions.tf` | Provider and Terraform constraints |
| `providers.tf` | Azure provider setup |
| `variables.tf` | Inputs that should be easy to change |
| `locals.tf` | Derived names, compact prefixes, and tags |
| `outputs.tf` | Values used for validation or later lessons |

## Review Habit
Read every plan for create, update, and destroy actions. A good lab run has a small, understandable plan and a clear cleanup step.

