# CLZ-280 - NAT Gateway Outbound

![NAT Gateway Outbound architecture](../assets/diagrams/network-foundation.svg)

## Goal

Make private-subnet Internet egress explicit and stable by associating a NAT Gateway and Standard public IP with the web subnet.

## Prerequisites

- Complete CLZ-270.
- Understand the difference between inbound access and outbound source translation.

## Architecture

The web subnet has no public workload or inbound service. A NAT Gateway association makes its future outbound connections use one allocated Standard public IPv4. Other subnets are not associated, making the scope visible.

## Resources And Cost

**Relative cost: Moderate.** NAT Gateway has an hourly charge and per-GB processing charge; the Standard public IP is also billable.

| Component | Purpose and principal cost driver |
|---|---|
| NAT Gateway | Subnet-level outbound source NAT; hourly and data-processing cost. |
| Standard public IP | Stable outbound identity. |
| VNet and subnets | Only the web subnet is associated in this lesson. |

## Inputs

| Input | Required substitution or decision |
|---|---|
| `subscription_id` | Required for Azure plan, apply, and destroy; use the exact subscription GUID. |
| `environment` | Keep `dev` for the lab unless testing another environment boundary. |
| `location` | Select a supported region with sufficient quota. |
| `name_prefix` | Use a short lowercase prefix. |

Keep real subscription IDs, CIDRs, domains, endpoint names, and secrets in untracked local files or environment variables.

## Deploy

Run from the repository root in PowerShell 7:

```powershell
Set-Location CLZ-280-nat-gateway-outbound
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
$natIp = terraform output -raw nat_gateway_public_ip
az network nat gateway list --resource-group $resourceGroup --query '[].{name:name,state:provisioningState,publicIps:publicIpAddresses[].id}' --output json
az network vnet subnet show --resource-group $resourceGroup --vnet-name (az network vnet list -g $resourceGroup --query '[0].name' -o tsv) --name web-snet --query natGateway.id --output tsv
$natIp
```

Expected result:

- The NAT Gateway provisioning state is `Succeeded` and it references the output public IP.
- The web subnet has a NAT Gateway ID.
- This control-plane-only lesson does not claim a data-plane egress test because it creates no workload.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| A workload still uses another source IP | Confirm its NIC is in the associated subnet and no higher-level egress path overrides the design. |
| The public IP cannot attach | Use a compatible Standard, static public IP in the same region. |
| Costs appear with no VM in the lesson | NAT Gateway is billed while provisioned even without workload traffic. |

## Cleanup

```powershell
$resourceGroup = terraform output -raw resource_group_name
terraform destroy -var "subscription_id=$subscriptionId"
az group exists --name $resourceGroup
```

The hourly NAT Gateway and public-IP resources are deleted.

## Production Delta

- Scale public IP prefixes and SNAT ports to the expected connection volume.
- NAT Gateway provides stable egress, not filtering; add Azure Firewall or another inspection/control layer when policy requires it.

## Exercises

1. Associate the app subnet in a temporary branch and identify the single new Terraform relationship.
2. Explain why NAT Gateway does not open an inbound route to a private VM.

## Navigation

<!-- lesson-navigation:start -->
[&larr; CLZ-270 - Windows VMSS Autoscaling](../CLZ-270-windows-vmss-autoscaling/README.md) | [Curriculum](../README.md#curriculum) | [CLZ-290 - Private DNS &rarr;](../CLZ-290-private-dns/README.md)
<!-- lesson-navigation:end -->
