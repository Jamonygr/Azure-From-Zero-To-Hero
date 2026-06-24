output "load_balancer_url" {
  description = "HTTP URL for the VMSS load balancer."
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "vmss_id" {
  description = "ID of the Windows VMSS."
  value       = azurerm_windows_virtual_machine_scale_set.web.id
}

