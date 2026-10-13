resource "random_password" "windows_admin" {
  length           = 20
  special          = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false

  keepers = {
    prefix = local.compact_prefix
  }
}

module "network" {
  source              = "../modules/network-core"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  prefix              = local.prefix
  tags                = local.tags
}

module "windows_iis_vmss" {
  source              = "../modules/windows-iis-vmss"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  prefix              = local.prefix
  subnet_id           = module.network.web_subnet_id
  admin_username      = var.admin_username
  admin_password      = random_password.windows_admin.result
  vm_size             = var.vm_size
  instance_count      = var.instance_count
  tags                = local.tags
  site_message        = "Azure From Zero To Hero capstone VMSS"
}

resource "azurerm_network_security_group" "web" {
  name                = "${local.prefix}-web-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags

  security_rule {
    name                       = "AllowHttpFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRdpFromAzureBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.40.20.0/26"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyOtherRdp"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = module.network.web_subnet_id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = module.network.vnet_name
  address_prefixes     = ["10.40.20.0/26"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "${local.prefix}-bas-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_bastion_host" "main" {
  name                = "${local.prefix}-bastion"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
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

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.prefix}-law"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

