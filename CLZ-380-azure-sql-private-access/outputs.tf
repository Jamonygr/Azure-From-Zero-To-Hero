output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
output "sql_server_name" {
  description = "Azure SQL server name."
  value       = azurerm_mssql_server.main.name
}

output "sql_admin_password" {
  description = "Generated SQL admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}

