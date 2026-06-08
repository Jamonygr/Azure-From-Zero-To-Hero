output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "public_dns_name_servers" {
  description = "Name servers for the optional public DNS zone."
  value       = var.create_public_dns_zone ? azurerm_dns_zone.public[0].name_servers : []
}

