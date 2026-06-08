# Security And Secrets

![Generated secret handling](../assets/diagrams/security-secrets.svg)

## Secret Rules
| Rule | Practice |
|---|---|
| Generate credentials | Use `random_password` for lab credentials |
| Mark outputs sensitive | Prevent casual terminal exposure |
| Keep real values local | Use `terraform.tfvars`, not committed files |
| Store later secrets centrally | Use Key Vault once introduced |

## Network Rules
Use narrow admin CIDR values and prefer Bastion for private RDP. Public endpoints are kept for specific teaching goals such as HTTP validation or load-balancing behavior.

## Private Platform Access
Private Endpoint lessons move storage and database access onto the VNet. Private DNS then resolves service names to private addresses.

![Private endpoint service access](../assets/diagrams/private-endpoint-sql.svg)

