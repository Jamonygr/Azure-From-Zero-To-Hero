output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "shared_output_keys" {
  description = "Output keys read from shared state."
  value       = keys(local.shared_outputs)
}

