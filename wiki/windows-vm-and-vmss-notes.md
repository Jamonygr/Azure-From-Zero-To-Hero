# Windows VM And VMSS Notes

![Windows IIS VM](../assets/diagrams/windows-iis-vm.svg)

## Image Standard
Chriz Labz uses Windows Server 2022 Azure Edition by default:

| Field | Value |
|---|---|
| Publisher | `MicrosoftWindowsServer` |
| Offer | `WindowsServer` |
| SKU | `2022-datacenter-azure-edition` |
| Version | `latest` |

## Access Pattern
Early labs use direct access only where it helps explain the resource. The preferred operating model is Azure Bastion RDP to private Windows VMs.

![Bastion RDP](../assets/diagrams/bastion-rdp.svg)

## IIS Bootstrap
IIS examples use PowerShell through Custom Script Extension. The validation page is written to `C:\inetpub\wwwroot\index.html`.

## VMSS Pattern
Windows VMSS lessons use a Standard Load Balancer, an HTTP probe, and an extension that installs IIS across instances.

![Load-balanced Windows tier](../assets/diagrams/load-balancer-vmss.svg)

