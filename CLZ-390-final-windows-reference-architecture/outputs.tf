output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "capstone_load_balancer_url" {
  description = "Capstone VMSS load balancer URL."
  value       = module.windows_iis_vmss.load_balancer_url
}

output "key_vault_name" {
  description = "Capstone Key Vault name."
  value       = azurerm_key_vault.lab.name
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}

