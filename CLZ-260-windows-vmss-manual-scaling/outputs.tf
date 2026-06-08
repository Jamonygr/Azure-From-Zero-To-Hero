output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "vmss_load_balancer_url" {
  description = "VMSS load balancer validation URL."
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}

