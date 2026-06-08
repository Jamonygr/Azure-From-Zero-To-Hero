resource "azurerm_dns_zone" "public" {
  count               = var.create_public_dns_zone ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

