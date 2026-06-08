output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "bastion_name" {
  description = "Azure Bastion name."
  value       = azurerm_bastion_host.main.name
}

output "private_windows_vm_id" {
  description = "Private Windows VM ID."
  value       = azurerm_windows_virtual_machine.private_web.id
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}

