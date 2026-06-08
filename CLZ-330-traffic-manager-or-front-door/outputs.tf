output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "traffic_manager_fqdn" {
  description = "Traffic Manager DNS name."
  value       = azurerm_traffic_manager_profile.web.fqdn
}

