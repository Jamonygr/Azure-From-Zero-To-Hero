# Azure Networking Glossary

![Network foundation](../assets/diagrams/network-foundation.svg)

## Core Terms
| Term | Meaning in Chriz Labz |
|---|---|
| Resource group | Boundary for one lab deployment |
| VNet | Private address space for lab resources |
| Subnet | Smaller network segment for a workload role |
| NSG | Rule set for subnet or NIC traffic |
| Public IP | Internet-facing endpoint used only where intentional |
| Load Balancer | Layer 4 distribution for HTTP or admin NAT patterns |
| NAT Gateway | Stable outbound access for private subnets |
| Private DNS | Internal name resolution linked to VNets |
| Private Endpoint | Private network entry point for an Azure platform service |

## Standard Subnet Model
| Subnet | CIDR | Use |
|---|---|---|
| web | `10.40.1.0/24` | IIS front-end and VMSS examples |
| app | `10.40.2.0/24` | Application tier expansion |
| data | `10.40.3.0/24` | Private endpoints and database access |
| mgmt | `10.40.10.0/24` | Management and operations patterns |

## Design Rule
Prefer private access for admin and data paths. Use public endpoints only when the lesson explicitly teaches public routing.

