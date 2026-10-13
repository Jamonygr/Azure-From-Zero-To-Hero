output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "state_storage_account_name" {
  description = "Storage account for state."
  value       = azurerm_storage_account.state.name
}

output "state_container_name" {
  description = "Storage container for state."
  value       = azurerm_storage_container.state.name
}

output "backend_configuration" {
  description = "Values to copy into backend.hcl and the CLZ-320 remote_state input."
  value = {
    resource_group_name  = azurerm_resource_group.lab.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
    key                  = "clz310.tfstate"
  }
}

