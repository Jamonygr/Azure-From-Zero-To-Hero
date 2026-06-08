output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "storage_account_name" {
  description = "Storage account reached by private endpoint."
  value       = azurerm_storage_account.private.name
}

output "private_endpoint_id" {
  description = "Private endpoint ID."
  value       = azurerm_private_endpoint.blob.id
}

