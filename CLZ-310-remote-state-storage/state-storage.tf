resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false

  keepers = {
    prefix = local.compact_prefix
  }
}

# Scanner compatibility: queue logging is configured with the provider's
# modern azurerm_storage_account_queue_properties resource below; Trivy does
# not currently associate that standalone resource with this storage account.
# Lab cost exception: customer-managed keys require a separate Key Vault,
# identity, and rotation workflow that are outside this backend lesson.
#trivy:ignore:AZU-0057
#trivy:ignore:AZU-0060
resource "azurerm_storage_account" "state" {
  name                              = substr("st${local.compact_prefix}${random_string.suffix.result}", 0, 24)
  resource_group_name               = azurerm_resource_group.lab.name
  location                          = azurerm_resource_group.lab.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
  tags                              = local.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = [split("/", var.backend_access_cidr)[0]]
  }
}

resource "azurerm_storage_account_queue_properties" "state" {
  storage_account_id = azurerm_storage_account.state.id

  logging {
    delete                = true
    read                  = true
    write                 = true
    version               = "1.0"
    retention_policy_days = 7
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

