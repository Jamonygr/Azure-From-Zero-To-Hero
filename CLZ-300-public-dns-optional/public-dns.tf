resource "azurerm_dns_zone" "public" {
  count               = var.create_public_dns_zone ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

check "owned_public_dns_zone" {
  assert {
    condition     = !var.create_public_dns_zone || lower(trimspace(var.dns_zone_name)) != "example.com"
    error_message = "Public DNS creation is disabled for example.com. Set dns_zone_name to a zone you own before enabling create_public_dns_zone."
  }
}

