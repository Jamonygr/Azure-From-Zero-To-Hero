output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "private_dns_zone_name" {
  description = "Private DNS zone name."
  value       = azurerm_private_dns_zone.internal.name
}

