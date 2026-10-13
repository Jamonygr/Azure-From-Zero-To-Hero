# Manual Azure Release Smoke Matrix

This is a maintainer-run release checklist, not an automated test. It documents
representative Azure deployments without authorizing CI, contributors, or this
repository to create resources. Run it only in an approved disposable
subscription with an explicit subscription ID, a budget, and an operator
responsible for cleanup.

## Entry Gate

- Local format, validation, lint, security, Markdown, Pester, and curriculum
  checks pass first.
- CLZ-110 confirms tenant, subscription, permissions, region, and quota.
- `git status` contains no secrets, state, real tfvars, or plan files.
- The operator records the start time, subscription ID suffix, region, expected
  cost tier, and resource-group name in the release record.
- Secrets are viewed only in a private terminal and are never copied into the
  release record.

Use this base sequence from each selected lesson:

```powershell
$subscriptionId = az account show --query id --output tsv
terraform init -lockfile=readonly
terraform fmt -check
terraform validate
terraform plan -var "subscription_id=$subscriptionId" -out tfplan
terraform show tfplan
terraform apply tfplan
```

Stop if the plan targets another subscription, contains an undocumented
replacement, broadens administrative access, or creates resources outside the
lesson's README.

## Smoke Cases

| Lesson | Release evidence | Acceptance criteria | Cleanup gate |
|---|---|---|---|
| CLZ-120 | Resource-group output, Azure provisioning state, no-change plan | One correctly tagged group in the selected subscription; second plan is empty | Destroy; state empty; `az group exists` is `false` |
| CLZ-200 | IIS URL, VM extension state, HTTP response | Extension is `Succeeded`; HTTP is 200 and contains the CLZ-200 page marker; RDP CIDR is one `/32` | Destroy VM, disk, IP, network, and group; group no longer exists |
| CLZ-210 | Bastion state, VM NIC/IP evidence, Bastion RDP session | Bastion is `Succeeded`; VM has no public IP; only Bastion public IP exists; private RDP succeeds | Destroy promptly because Bastion is hourly; group no longer exists |
| CLZ-260 | VMSS capacity/size, Load Balancer outbound rule, HTTP response | Requested integer capacity is healthy; HTTP is 200; explicit outbound rule exists | Destroy VMSS, Load Balancer, IP, disks, and group |
| CLZ-310/320 | Backend object, blob metadata, state lineage, consumer output keys | CLZ-310 migrates local state to `clz310.tfstate`; CLZ-320 reads real outputs through its typed object; placeholder values fail early | Destroy CLZ-320 first; remove/rename CLZ-310 backend block; migrate state local; verify; destroy CLZ-310 and backend |
| CLZ-380 | SQL public-network setting, endpoint approval, in-VNet DNS/TCP result | Public access is disabled; endpoint is `Approved`; in-VNet normal SQL FQDN resolves privately and TCP 1433 succeeds | Destroy SQL, endpoint, DNS, network, and group; group no longer exists |
| CLZ-390 | HTTP, NSG rules, Bastion, Key Vault, workspace, outbound rule | HTTP is 200; RDP source is Bastion subnet only; Bastion/vault/workspace succeed; explicit outbound exists | Destroy all capstone resources; state empty; group no longer exists |

## Lesson-Specific Commands

### CLZ-120

```powershell
$resourceGroup = terraform output -raw resource_group_name
az group show --name $resourceGroup --query '{state:properties.provisioningState,tags:tags}' --output json
terraform plan -var "subscription_id=$subscriptionId" -detailed-exitcode
```

The final command must exit `0`, not `2`.

### CLZ-200

```powershell
$url = terraform output -raw iis_url
(Invoke-WebRequest -Uri $url -UseBasicParsing).StatusCode
az vm extension list --resource-group (terraform output -raw resource_group_name) --output table
```

### CLZ-210

```powershell
$resourceGroup = terraform output -raw resource_group_name
az network bastion show --resource-group $resourceGroup --name (terraform output -raw bastion_name) --query provisioningState --output tsv
az vm show --ids (terraform output -raw private_windows_vm_id) --show-details --query '{private:privateIps,public:publicIps,power:powerState}' --output json
```

Complete one Bastion RDP session. Do not add temporary VM public access to make
the test pass. General Windows update/activation egress is intentionally absent
from this lesson and is assessed as a documented production delta.

### CLZ-260

```powershell
$resourceGroup = terraform output -raw resource_group_name
(Invoke-WebRequest -Uri (terraform output -raw vmss_load_balancer_url) -UseBasicParsing).StatusCode
az vmss list --resource-group $resourceGroup --query '[].{capacity:sku.capacity,size:sku.name,state:provisioningState}' --output table
$lb = az network lb list --resource-group $resourceGroup --query '[0].name' --output tsv
az network lb outbound-rule list --resource-group $resourceGroup --lb-name $lb --output table
```

### CLZ-310 and CLZ-320

Follow both lesson READMEs without shortcutting the state transitions. Capture
only nonsensitive output keys and state lineage/serial, not state content.

```powershell
# CLZ-310 after migration
$backend = terraform output -json backend_configuration | ConvertFrom-Json
az storage blob show --auth-mode login --account-name $backend.storage_account_name --container-name $backend.container_name --name $backend.key --query name --output tsv

# CLZ-320
terraform output -json shared_output_keys
```

For cleanup, destroy CLZ-320, return to CLZ-310, rename/remove untracked
`backend.tf`, run `terraform init -migrate-state`, verify local state, remove
runtime backend files, and only then destroy the backend resources.

### CLZ-380

```powershell
$server = terraform output -raw sql_server_name
$resourceGroup = terraform output -raw resource_group_name
az sql server show --resource-group $resourceGroup --name $server --query publicNetworkAccess --output tsv
az network private-endpoint list --resource-group $resourceGroup --query '[].privateLinkServiceConnections[0].privateLinkServiceConnectionState.status' --output tsv

# Run from an approved client in the linked VNet:
Resolve-DnsName "$server.database.windows.net"
Test-NetConnection "$server.database.windows.net" -Port 1433
```

Azure control-plane success from the operator laptop does not replace the
in-VNet DNS and TCP data-plane evidence.

### CLZ-390

```powershell
$resourceGroup = terraform output -raw resource_group_name
(Invoke-WebRequest -Uri (terraform output -raw capstone_load_balancer_url) -UseBasicParsing).StatusCode
az network nsg rule list --resource-group $resourceGroup --nsg-name (terraform output -raw web_network_security_group_name) --output table
az network bastion list --resource-group $resourceGroup --query '[].provisioningState' --output tsv
az keyvault show --name (terraform output -raw key_vault_name) --query properties.provisioningState --output tsv
```

## Exit Gate

- Every selected lesson records pass/fail and a concise failure category.
- Every created resource group is confirmed absent after destroy.
- Terraform state lists no managed resources after cleanup, except a deliberately
  retained backend that has a named owner and expiry.
- The operator checks Azure Resource Graph/cost views for orphaned VM, disk,
  public IP, Bastion, NAT, Private Endpoint, SQL, and Log Analytics resources.
- Runtime tfvars, backend files, plans, and state are removed locally; the
  committed dependency lockfiles remain.
- A failed cleanup blocks release until an owner and remediation time are recorded.
