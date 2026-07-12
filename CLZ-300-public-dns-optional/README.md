# CLZ-300 - Optional Public DNS

![Optional Public DNS architecture](../assets/diagrams/global-routing.svg)

## Goal

Model an Azure public DNS zone safely: the default creates no zone, while an explicit opt-in requires a domain you actually own and never accepts `example.com`.

## Prerequisites

- Complete CLZ-290.
- To enable creation, own a real public domain and understand registrar delegation.
- Do not change registrar name servers merely to finish the lesson.

## Architecture

A boolean controls whether Terraform creates one Azure DNS zone. When disabled, only the lesson resource group is managed. When enabled, Azure returns authoritative name servers, but public resolution occurs only after the domain owner delegates the zone at the registrar.

## Resources And Cost

**Relative cost: Low.** Azure DNS hosted zones and queries are low cost; registrar/domain charges are external.

| Component | Purpose and principal cost driver |
|---|---|
| Resource group | Always created for lifecycle consistency. |
| Optional public DNS zone | Created only when explicitly enabled with a non-placeholder owned domain. |
| Authoritative name servers | Outputs used for deliberate external delegation; Terraform does not change the registrar. |

## Inputs

| Input | Required substitution or decision |
|---|---|
| `subscription_id` | Required for Azure plan, apply, and destroy; use the exact subscription GUID. |
| `environment` | Keep `dev` for the lab unless testing another environment boundary. |
| `location` | Select a supported region with sufficient quota. |
| `name_prefix` | Use a short lowercase prefix. |
| `create_public_dns_zone` | Keep `false` for the safe path; set `true` only when you own and intend to manage the domain. |
| `dns_zone_name` | Replace `example.com` with the owned apex domain before enabling creation; placeholder use is rejected. |

Keep real subscription IDs, CIDRs, domains, endpoint names, and secrets in untracked local files or environment variables.

## Deploy

Run from the repository root in PowerShell 7:

```powershell
Set-Location CLZ-300-public-dns-optional
Copy-Item terraform.tfvars.example terraform.tfvars -ErrorAction SilentlyContinue
$subscriptionId = az account show --query id --output tsv
terraform init -lockfile=readonly
terraform fmt -check
terraform validate
terraform plan -var "subscription_id=$subscriptionId" -out tfplan
terraform show tfplan
terraform apply tfplan
```

The default applies only the resource group. Enabling the zone is a separate, deliberate run after editing both public-DNS inputs.

## Validate

```powershell
terraform output -json public_dns_name_servers
terraform plan -var "subscription_id=$subscriptionId" -var 'create_public_dns_zone=true' -var 'dns_zone_name=example.com'
$resourceGroup = terraform output -raw resource_group_name
az network dns zone list --resource-group $resourceGroup --query '[].{name:name,nameServers:nameServers}' --output json
```

Expected result:

- Default mode returns an empty name-server list and creates no DNS zone.
- The deliberately unsafe `example.com` enablement fails before Azure is changed.
- Enabled owned-domain mode returns Azure authoritative name servers; public lookup still requires registrar delegation.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| The safety check rejects the plan | Use an owned domain, or keep zone creation disabled. |
| The zone exists but Internet DNS does not resolve | Compare registrar delegation with the Azure name-server output and allow for DNS TTL/propagation. |
| A parent zone is already managed elsewhere | Coordinate delegation; do not create conflicting authorities. |

## Cleanup

```powershell
$resourceGroup = terraform output -raw resource_group_name
terraform destroy -var "subscription_id=$subscriptionId"
az group exists --name $resourceGroup
```

The optional zone and resource group are deleted. Restore registrar delegation separately if you changed it; Terraform does not own that external state.

## Production Delta

- Protect DNS changes with review, least privilege, activity logs, DNSSEC decisions, and documented registrar ownership.
- Use separate zones/subdomains per environment and test delegation/rollback before production cutover.

## Exercises

1. Run the default plan and prove there is no `azurerm_dns_zone` change.
2. With a domain you own, plan (but do not apply) enabled creation and identify the external delegation step.

## Navigation

<!-- lesson-navigation:start -->
[&larr; CLZ-290 - Private DNS](../CLZ-290-private-dns/README.md) | [Curriculum](../README.md#curriculum) | [CLZ-310 - Remote State Storage &rarr;](../CLZ-310-remote-state-storage/README.md)
<!-- lesson-navigation:end -->
