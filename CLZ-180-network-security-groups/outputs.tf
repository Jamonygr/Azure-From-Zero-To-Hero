output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "web_nsg_name" {
  description = "Web subnet NSG name."
  value       = azurerm_network_security_group.web.name
}

