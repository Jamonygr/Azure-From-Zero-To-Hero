output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "load_balancer_public_ip" {
  description = "Load balancer public IP."
  value       = azurerm_public_ip.lb.ip_address
}

output "rdp_nat_port" {
  description = "RDP NAT frontend port."
  value       = 50001
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}

