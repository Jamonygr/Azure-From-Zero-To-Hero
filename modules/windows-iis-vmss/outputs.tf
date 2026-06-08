output "load_balancer_url" {
  value = "http://${azurerm_public_ip.lb.ip_address}"
}

output "vmss_id" {
  value = azurerm_windows_virtual_machine_scale_set.web.id
}

