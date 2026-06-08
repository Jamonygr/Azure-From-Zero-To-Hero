output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "nat_gateway_public_ip" {
  description = "NAT Gateway outbound public IP."
  value       = azurerm_public_ip.nat.ip_address
}

