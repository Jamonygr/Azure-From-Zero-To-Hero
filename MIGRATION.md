# Migration Guide

This guide is for learners moving an older checkout to the polished curriculum
and smaller lesson interfaces. The repository is pre-1.0 learning material, so
input cleanup is intentionally breaking.

## Before Updating

1. Finish or record any exercise evidence you need.
2. Destroy every active ephemeral lesson from the folder and state that created
   it. Confirm `terraform state list` is empty.
3. If CLZ-320 exists, destroy it first. Then remove/rename CLZ-310's untracked
   `backend.tf`, run `terraform init -migrate-state` to copy state back to the
   implicit local backend, verify the state, and destroy CLZ-310.
4. Back up uncommitted notes outside the repository. Never copy state, secrets,
   plan files, or real tfvars into source control.
5. From the repository root, remove only the old generated provider lock files.
   They were ignored in earlier versions and can block Git from checking out the
   newly tracked, cross-platform lock files:

   ```powershell
   Get-ChildItem -Path . -Recurse -Force -Filter .terraform.lock.hcl |
     Where-Object FullName -NotMatch '\\.terraform\\' |
     Remove-Item -Force
   ```

6. Pull the new version only after `git status` contains no lab runtime data you
   still depend on.

Destroying disposable labs first is the supported upgrade path. It avoids
mixing an older state shape with renamed global resources and changed inputs.

## Regenerate Local Inputs

Do not reuse the old universal `terraform.tfvars`. Each lesson now declares
only inputs it consumes.

```powershell
Set-Location <lesson-folder>
Remove-Item terraform.tfvars -ErrorAction SilentlyContinue
Copy-Item terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```

Review these interface changes:

| Old input | Current interface |
|---|---|
| Configurable `lab_id` | Removed; every lesson ID is fixed in `locals.tf` |
| Universal 18-variable file | Common inputs plus only lesson-specific values |
| CLZ-250 `vm_names` map | `vm_definitions = map(object({ vm_size = string, role = string }))` |
| CLZ-270 standalone capacity values | `autoscale_capacity = object({ minimum, default, maximum })` with integer/order validation |
| CLZ-320 four remote-state strings | Required `remote_state` object with resource group, account, container, and key |
| Placeholder public DNS values | CLZ-300 refuses `example.com` when zone creation is enabled |
| Broad administrator access | RDP and service-firewall examples require a real IPv4 `/32` |

CLZ-310 and CLZ-320 no longer accept a deployable placeholder storage account.
Copy the typed `backend_configuration` output from CLZ-310 into CLZ-320.

## Expected Replacements

Stable random suffixes make global names collision-resistant. Terraform keeps
the existing resource addresses, but an older deployed object can require
replacement because its Azure name changes:

| Lesson | Address | Change |
|---|---|---|
| CLZ-310 | `azurerm_storage_account.state` | The persisted suffix keeper and infrastructure encryption replace the backend storage account; complete the migration-back procedure before upgrading |
| CLZ-330 | `azurerm_traffic_manager_profile.web` | Profile name gains a persisted suffix |
| CLZ-340 | `azurerm_key_vault.lab` | Vault name gains a persisted suffix |
| CLZ-350 | `azurerm_storage_account.private` | The persisted suffix keeper and infrastructure encryption replace the private storage account |
| CLZ-380 | `azurerm_mssql_server.main` | SQL server name gains a persisted suffix |
| CLZ-390 | `azurerm_key_vault.lab` | Capstone vault name gains a persisted suffix |

CLZ-330, CLZ-340, CLZ-380, and CLZ-390 add `random_string.suffix`. CLZ-310 and
CLZ-350 add `keepers` to their existing suffix resources, which intentionally
selects a new persisted value. Other existing Terraform addresses are
preserved where practical. If an environment cannot tolerate these
replacements, do not apply the upgraded configuration; plan and design a
separately reviewed migration.

The safety overhaul also removes these former addresses. The supported
destroy-first upgrade leaves no state to reconcile. If you inspect an old live
state instead, expect Terraform to propose the listed deletions:

| Lesson(s) | Removed address | Reason |
|---|---|---|
| CLZ-100, CLZ-110 | `azurerm_resource_group.lab` | These opening lessons are now credential-free and create no Azure resources |
| CLZ-190, CLZ-200, CLZ-230, CLZ-240, CLZ-250 | `azurerm_subnet_network_security_group_association.web` | The same NSG is attached directly to the teaching NIC instead of the whole subnet |
| CLZ-210 | `azurerm_network_security_rule.allow_http`, `azurerm_subnet_network_security_group_association.web` | The Bastion lesson is private; HTTP ingress is removed and the NSG moves to the VM NIC |
| CLZ-220 | `azurerm_network_security_rule.allow_admin_rdp`, `azurerm_subnet_network_security_group_association.web` | Direct RDP is removed and the backend NSG moves to the NIC |
| CLZ-260, CLZ-270 | `azurerm_network_security_rule.allow_admin_rdp` | VMSS lessons expose only load-balanced HTTP; they do not teach direct RDP |

## Workflow Examples

The obsolete CLZ-370 single workflow and legacy two-word lab-root paths are retired. The
current examples are:

- `CLZ-370-github-actions-terraform/.github/workflows/terraform-validate.yml.example`
  for credential-free pull-request checks.
- `CLZ-370-github-actions-terraform/.github/workflows/terraform-plan-oidc.yml.example`
  for a manual OIDC plan in the `azure-lab-plan` environment.

Neither example applies infrastructure. Update trigger paths and working
directories together if you copy an example into another repository.

## Verify the Upgrade

```powershell
./scripts/Sync-AzureFromZeroToHeroCurriculum.ps1 -Check
./scripts/Test-AzureFromZeroToHeroTerraform.ps1 -Format -Validate -Test -LockfileReadonly
./scripts/Test-AzureFromZeroToHeroDocs.ps1
```

For a new Azure run, repeat CLZ-110, capture the exact subscription ID, and
start with CLZ-120. Review every saved plan before apply and follow the lesson's
cleanup verification.
