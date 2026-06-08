output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "key_vault_name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.lab.name
}

output "secret_name" {
  description = "Stored secret name."
  value       = azurerm_key_vault_secret.windows_admin_password.name
}

