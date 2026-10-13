# CLZ-240 - Count with Windows VMs

![Count with Windows VMs architecture](../assets/diagrams/windows-iis-vm.svg)

## Goal

Use `count` to create and index a homogeneous set of Windows VMs, NICs, public IPs, and disks while observing the consequences of positional identity.

## Prerequisites

- Complete CLZ-230.
- Quota and budget for the selected number of Windows VMs.
- A public administrator IPv4 `/32` for this intentional introductory public-IP pattern.

## Architecture

Each counted VM receives a matching counted NIC and Standard public IP. Numeric indexes connect resources and shape Terraform addresses such as `[0]` and `[1]`. The instances intentionally use public-IP egress so the lesson stays focused on `count`.

## Resources And Cost

**Relative cost: High.** Cost grows almost linearly with `instance_count`: each element adds a Windows VM, disk, NIC, and public IP.

| Component | Purpose and principal cost driver |
|---|---|
| Counted Windows VMs and disks | Homogeneous compute set; primary cost driver. |
| Counted NICs and public IPs | One-to-one indexed network dependencies and intentional public egress. |
| Shared VNet and NSG | Common subnet policy with RDP scoped to one administrator `/32`. |

## Inputs

| Input | Required substitution or decision |
|---|---|
| `subscription_id` | Required for plan, apply, and destroy; use the exact subscription GUID. |
| `environment` | Keep `dev` for an ephemeral lab unless testing an environment boundary. |
| `location` | Select a supported region with adequate quota. |
| `name_prefix` | Use a short lowercase prefix for derived names. |
| `admin_username` | One nonreserved administrator name used across the set. |
| `admin_cidr` | Required current public IPv4 `/32`; broad RDP access is rejected. |
| `vm_size` | Size applied to every counted VM. |
| `instance_count` | Positive integer; keep the default small to control cost. |

Keep real subscription IDs, CIDRs, and secrets in untracked `terraform.tfvars` or environment variables.

## Deploy

Run from the repository root in PowerShell 7:

```powershell
Set-Location CLZ-240-count-windows-vms
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
terraform state list | Select-String '\[[0-9]+\]'
terraform output -json windows_vm_public_ips | ConvertFrom-Json
az vm list --resource-group $resourceGroup --show-details --query '[].{name:name,size:hardwareProfile.vmSize,ip:publicIps,power:powerState}' --output table
```

Expected result:

- State addresses use numeric indexes consistently across VM, NIC, and public-IP resources.
- The output contains one address per requested instance.
- Azure reports the requested count and uniform size.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Reducing count deletes an unexpected VM | Count uses positional identity and removes from the highest indexes; review the saved plan carefully. |
| A fractional count is rejected | Use a whole number; instance cardinality cannot be fractional. |
| Quota fails partway through | Destroy partial resources, reduce the count/size, or use an approved region. |

## Cleanup

```powershell
$resourceGroup = terraform output -raw resource_group_name
terraform destroy -var "subscription_id=$subscriptionId"
terraform state list
az group exists --name $resourceGroup
```

All indexed VMs, disks, NICs, public IPs, and the resource group are deleted.

## Production Delta

- Intentional teaching exception: remove direct public VM access and use private management plus explicit governed egress.
- Use `for_each` for durable named identity when elements are not truly interchangeable, or VMSS for one scalable workload.

## Exercises

1. Increase the count by one and predict every new resource address before planning.
2. Remove an element conceptually and explain why positional identity can be risky.

## Navigation

<!-- lesson-navigation:start -->
[&larr; CLZ-230 - Load Balancer NAT Rules](../CLZ-230-load-balancer-nat-rules/README.md) | [Curriculum](../README.md#curriculum) | [CLZ-250 - For Each with Windows VMs &rarr;](../CLZ-250-for-each-windows-vms/README.md)
<!-- lesson-navigation:end -->
