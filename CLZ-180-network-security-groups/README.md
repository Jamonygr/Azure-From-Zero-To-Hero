# CLZ-180 - Network Security Groups

![Network Security Groups architecture](../assets/diagrams/network-foundation.svg)

## Goal

Protect the web subnet with deterministic NSG priorities, public HTTP for the teaching service, and RDP limited to one administrator IPv4 address.

## Prerequisites

- Complete CLZ-170.
- Discover your current public IPv4 address and express it as a `/32` CIDR.

## Architecture

The CLZ-170 network is recreated in this independent lesson. A web NSG is associated with the web subnet. HTTP is allowed for the example service, while RDP is admitted only from `admin_cidr`; Azure's default deny rules handle other unsolicited inbound traffic.

## Resources And Cost

**Relative cost: Low.** NSGs and rules have no direct charge; traffic processing and later workloads can be billable.

| Component | Purpose and principal cost driver |
|---|---|
| VNet and four subnets | Network boundary used to teach subnet-level policy. |
| Web NSG association | Applies all web rules to NICs placed in the subnet. |
| HTTP and RDP rules | Port 80 teaching access and tightly scoped port 3389 administration. |

## Inputs

| Input | Required substitution or decision |
|---|---|
| `subscription_id` | Required for plan, apply, and destroy; use the exact subscription GUID. |
| `environment` | Keep `dev` for an ephemeral lab unless testing an environment boundary. |
| `location` | Select a supported region with adequate quota. |
| `name_prefix` | Use a short lowercase prefix for derived names. |
| `admin_cidr` | Required: replace the documentation address with your current public IPv4 plus `/32`; broad ranges are rejected. |

Keep real subscription IDs, CIDRs, and secrets in untracked `terraform.tfvars` or environment variables.

## Deploy

Run from the repository root in PowerShell 7:

```powershell
Set-Location CLZ-180-network-security-groups
if (-not (Test-Path terraform.tfvars)) {
  Copy-Item terraform.tfvars.example terraform.tfvars
}
$subscriptionId = az account show --query id --output tsv
terraform init -lockfile=readonly
terraform fmt -check
terraform validate
terraform plan -var "subscription_id=$subscriptionId" -out tfplan
terraform show tfplan
terraform apply tfplan
```

## Validate

```powershell
$resourceGroup = terraform output -raw resource_group_name
$nsg = terraform output -raw web_nsg_name
az network nsg rule list --resource-group $resourceGroup --nsg-name $nsg --query '[].{name:name,priority:priority,source:sourceAddressPrefix,port:destinationPortRange,access:access}' --output table
terraform plan -var "subscription_id=$subscriptionId" -var 'admin_cidr=0.0.0.0/0'
```

Expected result:

- HTTP and administrator RDP rules have unique priorities and `Allow` access.
- The RDP rule source is exactly the supplied `/32`.
- The deliberately broad negative plan fails before Azure is changed.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| The safety check rejects the CIDR | Use a routable IPv4 `/32`; do not substitute `0.0.0.0/0`, `*`, or a large network. |
| A rule priority conflicts | Give each custom rule a unique value from 100 through 4096. |
| RDP remains unreachable later | Confirm both the NSG path and whether the workload actually has a public, NAT, or Bastion ingress path. |

## Cleanup

```powershell
$resourceGroup = terraform output -raw resource_group_name
terraform destroy -var "subscription_id=$subscriptionId"
az group exists --name $resourceGroup
```

Azure CLI returns `false`; no NSG remains associated with a deleted subnet.

## Production Delta

- Prefer Azure Bastion, Just-In-Time access, VPN, or private management over direct Internet RDP.
- Restrict web ingress to the real proxy/load-balancer path and use Application Security Groups where they simplify intent.

## Exercises

1. Change the RDP source to another safe `/32` and identify the in-place rule update.
2. Add a deny rule with a valid priority and explain how Azure evaluates it against the allow rules.

## Navigation

<!-- lesson-navigation:start -->
[&larr; CLZ-170 - Virtual Network Foundation](../CLZ-170-virtual-network-foundation/README.md) | [Curriculum](../README.md#curriculum) | [CLZ-190 - Windows VM Basics &rarr;](../CLZ-190-windows-vm-basics/README.md)
<!-- lesson-navigation:end -->
