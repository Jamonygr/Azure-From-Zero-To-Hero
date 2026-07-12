resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false

  keepers = {
    prefix = local.compact_prefix
  }
}

resource "random_password" "windows_admin" {
  length           = 20
  special          = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
data "azurerm_client_config" "current" {}

# Lab cleanup exception: purge protection is disabled so learners can fully
# remove the globally named vault after the exercise.
#trivy:ignore:AZU-0016
resource "azurerm_key_vault" "lab" {
  name                       = "kv-${local.compact_prefix}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.lab.location
  resource_group_name        = azurerm_resource_group.lab.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = local.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [split("/", var.key_vault_access_cidr)[0]]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Set"
    ]
  }
}

resource "azurerm_key_vault_secret" "windows_admin_password" {
  name         = "windows-admin-password"
  value        = random_password.windows_admin.result
  key_vault_id = azurerm_key_vault.lab.id
  tags         = local.tags
}

