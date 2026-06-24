# Azure From Zero To Hero Modules

Reusable modules are introduced only after the core resource patterns have been shown directly in the lesson folders. They stay small so each lab user can still read every resource.

| Module | Used by | Purpose |
|---|---|---|
| `network-core` | CLZ-390 | Shared VNet and subnet foundation for the capstone |
| `windows-iis-vmss` | CLZ-260, CLZ-270, CLZ-390 | Standard Load Balancer, Windows VMSS, and IIS bootstrap pattern |

Earlier lessons keep resources explicit for learning. VMSS lessons use the shared module once the pattern has become repetitive, while autoscale and capstone-specific resources remain visible in their lesson folders.
