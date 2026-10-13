# CLZ-230 - Load Balancer NAT Rules

![Load Balancer NAT Rules architecture](../assets/diagrams/load-balancer-vmss.svg)

## Goal

Understand per-instance inbound NAT by mapping one scoped public frontend port to RDP on a private Windows backend while HTTP remains load-balanced.

## Prerequisites

- Complete CLZ-220.
- A current administrator public IPv4 `/32`; broad RDP sources are rejected.
- Use this NAT pattern only for the lesson, not as the preferred management design.

## Architecture

A Standard Load Balancer serves HTTP on port 80 across two Windows backends and maps frontend TCP 50001 to RDP 3389 on the first backend, `web[0]`. The web NSG limits that admin flow to `admin_cidr`. An explicit outbound rule supplies backend egress without relying on inbound SNAT.

## Resources And Cost

**Relative cost: Moderate.** Two Windows VMs and their disks dominate; Standard public IP and outbound traffic add cost.

| Component | Purpose and principal cost driver |
|---|---|
| Standard Load Balancer and public IP | HTTP, health probe, explicit outbound, and one inbound NAT rule. |
| Two Windows IIS VMs | Both private NICs join the HTTP pool; only `web[0]` is associated with the RDP NAT rule. |
| Web NSG | Allows HTTP and one `/32` administrator source for RDP. |

## Inputs

| Input | Required substitution or decision |
|---|---|
| `subscription_id` | Required for plan, apply, and destroy; use the exact subscription GUID. |
| `environment` | Keep `dev` for an ephemeral lab unless testing an environment boundary. |
| `location` | Select a supported region with adequate quota. |
| `name_prefix` | Use a short lowercase prefix for derived names. |
| `admin_username` | Nonreserved Windows administrator name. |
| `admin_cidr` | Required public IPv4 `/32` permitted to reach frontend port 50001. |
| `vm_size` | Small available Windows size. |

Keep real subscription IDs, CIDRs, and secrets in untracked `terraform.tfvars` or environment variables.

## Deploy

Run from the repository root in PowerShell 7:

```powershell
Set-Location CLZ-230-load-balancer-nat-rules
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
$ip = terraform output -raw load_balancer_public_ip
$port = terraform output -raw rdp_nat_port
Test-NetConnection -ComputerName $ip -Port $port
$lb = az network lb list --resource-group $resourceGroup --query '[0].name' -o tsv
az network lb inbound-nat-rule list --resource-group $resourceGroup --lb-name $lb --query '[].{front:frontendPort,back:backendPort,protocol:protocol}' --output table
az network lb outbound-rule list --resource-group $resourceGroup --lb-name $lb --output table
```

Expected result:

- The TCP test to frontend port `50001` succeeds only from the configured `/32`.
- Azure reports the `50001` to `3389` mapping.
- An explicit outbound rule exists for the backend pool.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Port 50001 is closed | Check your current source IP, NSG rule, NAT association, VM state, and guest RDP service. |
| RDP opens the wrong target | Inspect the NIC-to-NAT-rule association; per-instance rules are not general load balancing. |
| The safety check blocks the plan | Replace any wildcard/broad CIDR with one real administrator IPv4 `/32`. |

## Cleanup

```powershell
$resourceGroup = terraform output -raw resource_group_name
terraform destroy -var "subscription_id=$subscriptionId"
az group exists --name $resourceGroup
```

The NAT exposure, both backend VMs, load balancer, and public IP are deleted.

## Production Delta

- Replace Internet-facing RDP NAT with Bastion, VPN/ExpressRoute, or another audited private management path.
- If NAT rules remain temporarily, add Just-In-Time controls, monitoring, time-bounded sources, and incident response ownership.

## Exercises

1. Change the frontend port and identify every place the validation command must change.
2. Compare an inbound NAT rule with a load-balancing rule and an outbound rule.

## Navigation

<!-- lesson-navigation:start -->
[&larr; CLZ-220 - Standard Load Balancer for Windows](../CLZ-220-standard-load-balancer-windows/README.md) | [Curriculum](../README.md#curriculum) | [CLZ-240 - Count with Windows VMs &rarr;](../CLZ-240-count-windows-vms/README.md)
<!-- lesson-navigation:end -->
