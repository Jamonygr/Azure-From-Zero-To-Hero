# Companion Book Errata and Repository Crosswalk

This page maps the June 2026 *Beyond Clickopz* PDF to the current repository.
The PDF page content is preserved as published; use this page when a printed
path, workflow, title, or opening-sequence instruction differs from the live
curriculum.

## Important Corrections

| PDF file page | Printed guidance | Current guidance |
|---:|---|---|
| 8 and 12 | Repository URL is displayed with spacing around hyphens | Use <https://github.com/Jamonygr/Azure-From-Zero-To-Hero> |
| 12-20 | Setup/foundations text implies the early lessons create Azure resources | CLZ-090 is optional local contributor setup; CLZ-100 is credential-free foundations; CLZ-110 performs explicit read-only Azure readiness checks; CLZ-120 is the first Azure deployment |
| 21-23 | CLZ-120 may rely on the active CLI subscription when `subscription_id = null` | Capture the intended subscription GUID and pass it explicitly for plan, apply, and destroy |
| 85 | Chapter title is “Traffic Manager Or Front Door” | Display title is **Traffic Manager Global Routing**; Terraform deploys Traffic Manager, while the README compares when Front Door is appropriate |
| 95-97 | CLZ-370 creates a resource group and uses one combined workflow | CLZ-370 creates no Azure resources and now separates credential-free validation from a manually approved OIDC plan |
| 96 | Pull-request path uses the obsolete `Chriz&#32;Labz/**` root | Use `CLZ-370-github-actions-terraform/**` |
| 96 | Working directory uses the obsolete `Chriz&#32;Labz/` root before the CLZ-370 folder | Use `CLZ-370-github-actions-terraform` from repository root |
| 96-97 | Workflow is described as both pull request and manual Azure planning | Use `.github/workflows/terraform-validate.yml.example` for pull requests and `.github/workflows/terraform-plan-oidc.yml.example` for manual OIDC planning within the CLZ-370 lesson |

The current CLZ-370 examples pin third-party actions by full commit SHA, set
timeouts and concurrency behavior, and contain no `terraform apply` step. The
OIDC example requires the protected `azure-lab-plan` GitHub environment plus
`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` variables.

## Chapter-to-Lesson Crosswalk

| Chapter | Current lesson |
|---:|---|
| 0 | [CLZ-090 - Optional Windows Contributor Workstation Setup](../CLZ-090-optional-vscode-terraform-powershell-setup/README.md) |
| 1 | [CLZ-100 - Terraform Foundations](../CLZ-100-foundations/README.md) |
| 2 | [CLZ-110 - Azure CLI and Subscription Readiness](../CLZ-110-windows-workstation-setup/README.md) |
| 3 | [CLZ-120 - First Azure Deployment and Terraform Workflow](../CLZ-120-terraform-core-workflow/README.md) |
| 4 | [CLZ-130 - Provider Authentication](../CLZ-130-provider-authentication/README.md) |
| 5 | [CLZ-140 - Resource Groups and Tags](../CLZ-140-resource-groups-tags/README.md) |
| 6 | [CLZ-150 - Variables, Locals, and Outputs](../CLZ-150-variables-locals-outputs/README.md) |
| 7 | [CLZ-160 - State and Locking Basics](../CLZ-160-state-and-locking-basics/README.md) |
| 8 | [CLZ-170 - Virtual Network Foundation](../CLZ-170-virtual-network-foundation/README.md) |
| 9 | [CLZ-180 - Network Security Groups](../CLZ-180-network-security-groups/README.md) |
| 10 | [CLZ-190 - Windows VM Basics](../CLZ-190-windows-vm-basics/README.md) |
| 11 | [CLZ-200 - Windows VM IIS Bootstrap](../CLZ-200-windows-vm-iis-bootstrap/README.md) |
| 12 | [CLZ-210 - Azure Bastion RDP](../CLZ-210-azure-bastion-rdp/README.md) |
| 13 | [CLZ-220 - Standard Load Balancer for Windows](../CLZ-220-standard-load-balancer-windows/README.md) |
| 14 | [CLZ-230 - Load Balancer NAT Rules](../CLZ-230-load-balancer-nat-rules/README.md) |
| 15 | [CLZ-240 - Count with Windows VMs](../CLZ-240-count-windows-vms/README.md) |
| 16 | [CLZ-250 - For Each with Windows VMs](../CLZ-250-for-each-windows-vms/README.md) |
| 17 | [CLZ-260 - Windows VMSS Manual Scaling](../CLZ-260-windows-vmss-manual-scaling/README.md) |
| 18 | [CLZ-270 - Windows VMSS Autoscaling](../CLZ-270-windows-vmss-autoscaling/README.md) |
| 19 | [CLZ-280 - NAT Gateway Outbound](../CLZ-280-nat-gateway-outbound/README.md) |
| 20 | [CLZ-290 - Private DNS](../CLZ-290-private-dns/README.md) |
| 21 | [CLZ-300 - Optional Public DNS](../CLZ-300-public-dns-optional/README.md) |
| 22 | [CLZ-310 - Remote State Storage](../CLZ-310-remote-state-storage/README.md) |
| 23 | [CLZ-320 - Cross-Environment State](../CLZ-320-cross-environment-state/README.md) |
| 24 | [CLZ-330 - Traffic Manager Global Routing](../CLZ-330-traffic-manager-or-front-door/README.md) |
| 25 | [CLZ-340 - Key Vault Secrets](../CLZ-340-key-vault-secrets/README.md) |
| 26 | [CLZ-350 - Private Endpoint for Storage](../CLZ-350-private-endpoint-storage/README.md) |
| 27 | [CLZ-360 - Azure Monitor and Log Analytics](../CLZ-360-azure-monitor-log-analytics/README.md) |
| 28 | [CLZ-370 - GitHub Actions for Terraform](../CLZ-370-github-actions-terraform/README.md) |
| 29 | [CLZ-380 - Azure SQL Private Access](../CLZ-380-azure-sql-private-access/README.md) |
| 30 | [CLZ-390 - Final Windows Reference Architecture](../CLZ-390-final-windows-reference-architecture/README.md) |

The repository READMEs, Terraform files, catalog, and workflow examples are the
source of truth when they differ from the book.

## Download and Rights

The PDF is available at no charge for personal reading. Its existing **all
rights reserved** notice remains in force. “Free” describes the download price;
it does not place the book in the public domain, grant an open-content license,
or permit redistribution beyond the rights already stated in the PDF.

This clarification does not add or change a software license for the repository.
