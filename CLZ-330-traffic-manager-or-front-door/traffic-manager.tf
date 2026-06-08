resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_traffic_manager_profile" "web" {
  name                   = "${local.prefix}-tm"
  resource_group_name    = azurerm_resource_group.lab.name
  traffic_routing_method = "Priority"
  tags                   = local.tags

  dns_config {
    relative_name = substr("tm-${local.compact_prefix}-${random_string.suffix.result}", 0, 63)
    ttl           = 60
  }

  monitor_config {
    protocol = "HTTPS"
    port     = 443
    path     = "/"
  }
}

resource "azurerm_traffic_manager_external_endpoint" "primary" {
  name       = "primary"
  profile_id = azurerm_traffic_manager_profile.web.id
  target     = var.primary_endpoint_fqdn
  priority   = 1
}

resource "azurerm_traffic_manager_external_endpoint" "secondary" {
  name       = "secondary"
  profile_id = azurerm_traffic_manager_profile.web.id
  target     = var.secondary_endpoint_fqdn
  priority   = 2
}

