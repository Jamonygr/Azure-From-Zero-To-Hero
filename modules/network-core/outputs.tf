output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.main.id
}

output "web_subnet_id" {
  description = "Web subnet ID."
  value       = azurerm_subnet.web.id
}

output "data_subnet_id" {
  description = "Data subnet ID."
  value       = azurerm_subnet.data.id
}

