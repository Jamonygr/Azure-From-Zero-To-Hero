resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Lab exception: this storage account stays reachable from the learner workstation
# so the remote-state lesson can create and inspect the backend without a private network.
#trivy:ignore:AVD-AZU-0012
#trivy:ignore:AZU-0012
resource "azurerm_storage_account" "state" {
  name                            = substr("st${local.compact_prefix}${random_string.suffix.result}", 0, 24)
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

