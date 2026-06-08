resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.prefix}-law"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_monitor_action_group" "ops" {
  name                = "${local.prefix}-ops-ag"
  resource_group_name = azurerm_resource_group.lab.name
  short_name          = "clzops"
  tags                = local.tags
}

