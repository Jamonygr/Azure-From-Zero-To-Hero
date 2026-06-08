output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.main.name
}

