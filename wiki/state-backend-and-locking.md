# State Backend And Locking

![Remote state](../assets/diagrams/remote-state.svg)

Terraform state is the map between configuration and Azure resource IDs. It is operational data, not documentation.

## Local State
Early lessons use local state so the workflow stays easy to inspect. Local state is acceptable for isolated practice, but it should not be committed.

## Remote State
The remote-state lesson creates an Azure Storage account and private container. Later lessons can read selected outputs from that state file.

## State Safety Checklist
| Rule | Reason |
|---|---|
| Keep one state per lab or environment | Prevent accidental cross-environment changes |
| Do not edit state manually | Manual edits can break resource tracking |
| Do not commit state files | State may contain sensitive or operational data |
| Destroy from the owning folder | Terraform needs the matching configuration and state |
| Record outputs before cleanup | Later lessons may need storage account or endpoint values |

## Backend Shape
The backend uses a storage account, a private container, and one key per environment. The example key pattern is `clz-dev.tfstate`.

