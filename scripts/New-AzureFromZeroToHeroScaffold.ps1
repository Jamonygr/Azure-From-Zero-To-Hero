param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Write-LabFile {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Content
  )

  $target = Join-Path $Root $RelativePath
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }

  if ((Test-Path -LiteralPath $target) -and -not $Force) {
    throw "Refusing to overwrite $RelativePath. Re-run with -Force."
  }

  $normalized = $Content.TrimStart("`r", "`n").TrimEnd() + "`r`n"
  Set-Content -LiteralPath $target -Value $normalized -Encoding utf8
}

$Lessons = @(
  [ordered]@{ Number = 1; Id = "CLZ-100"; Folder = "CLZ-100-foundations"; Title = "Foundations"; Topic = "IaC, Terraform, and the Azure lab model"; Kind = "basic"; Focus = "Create the first tagged resource group and learn the lab workflow." },
  [ordered]@{ Number = 2; Id = "CLZ-110"; Folder = "CLZ-110-windows-workstation-setup"; Title = "Windows Workstation Setup"; Topic = "Terraform, Azure CLI, VS Code, Git, and PowerShell"; Kind = "basic"; Focus = "Confirm the Windows toolchain and subscription context." },
  [ordered]@{ Number = 3; Id = "CLZ-120"; Folder = "CLZ-120-terraform-core-workflow"; Title = "Terraform Core Workflow"; Topic = "init, fmt, validate, plan, apply, and destroy"; Kind = "basic"; Focus = "Practice the repeatable Terraform command loop." },
  [ordered]@{ Number = 4; Id = "CLZ-130"; Folder = "CLZ-130-provider-authentication"; Title = "Provider Authentication"; Topic = "Azure provider and CLI authentication"; Kind = "basic"; Focus = "Use the Azure provider with an explicit subscription setting." },
  [ordered]@{ Number = 5; Id = "CLZ-140"; Folder = "CLZ-140-resource-groups-tags"; Title = "Resource Groups And Tags"; Topic = "Resource groups, standard tags, and naming"; Kind = "basic"; Focus = "Apply the Azure From Zero To Hero naming and tagging model." },
  [ordered]@{ Number = 6; Id = "CLZ-150"; Folder = "CLZ-150-variables-locals-outputs"; Title = "Variables Locals Outputs"; Topic = "Variables, locals, outputs, and tfvars examples"; Kind = "basic"; Focus = "Control the same Terraform with input values." },
  [ordered]@{ Number = 7; Id = "CLZ-160"; Folder = "CLZ-160-state-and-locking-basics"; Title = "State And Locking Basics"; Topic = "Local state safety and cleanup discipline"; Kind = "basic"; Focus = "Understand what Terraform records before adding shared state." },
  [ordered]@{ Number = 8; Id = "CLZ-170"; Folder = "CLZ-170-virtual-network-foundation"; Title = "Virtual Network Foundation"; Topic = "VNet, subnets, and address plan"; Kind = "network"; Focus = "Build the base network used by later Windows workloads." },
  [ordered]@{ Number = 9; Id = "CLZ-180"; Folder = "CLZ-180-network-security-groups"; Title = "Network Security Groups"; Topic = "NSGs and rule design"; Kind = "security"; Focus = "Attach HTTP and controlled RDP rules to the web subnet." },
  [ordered]@{ Number = 10; Id = "CLZ-190"; Folder = "CLZ-190-windows-vm-basics"; Title = "Windows VM Basics"; Topic = "First Windows VM"; Kind = "windows-vm"; Focus = "Deploy a Windows Server VM with generated credentials." },
  [ordered]@{ Number = 11; Id = "CLZ-200"; Folder = "CLZ-200-windows-vm-iis-bootstrap"; Title = "Windows VM IIS Bootstrap"; Topic = "IIS with PowerShell Custom Script Extension"; Kind = "iis-vm"; Focus = "Install IIS and publish a validation page." },
  [ordered]@{ Number = 12; Id = "CLZ-210"; Folder = "CLZ-210-azure-bastion-rdp"; Title = "Azure Bastion RDP"; Topic = "Bastion subnet, Bastion host, and private RDP"; Kind = "bastion"; Focus = "Reach the Windows VM privately through Azure Bastion." },
  [ordered]@{ Number = 13; Id = "CLZ-220"; Folder = "CLZ-220-standard-load-balancer-windows"; Title = "Standard Load Balancer Windows"; Topic = "Public Standard Load Balancer with Windows backend"; Kind = "load-balancer"; Focus = "Balance HTTP traffic across two IIS nodes." },
  [ordered]@{ Number = 14; Id = "CLZ-230"; Folder = "CLZ-230-load-balancer-nat-rules"; Title = "Load Balancer NAT Rules"; Topic = "Controlled RDP NAT rule pattern"; Kind = "nat-rules"; Focus = "Expose one controlled admin entry through a Standard Load Balancer rule." },
  [ordered]@{ Number = 15; Id = "CLZ-240"; Folder = "CLZ-240-count-windows-vms"; Title = "Count Windows VMs"; Topic = "Terraform count with Windows VMs"; Kind = "count-vms"; Focus = "Scale identical Windows VMs with count." },
  [ordered]@{ Number = 16; Id = "CLZ-250"; Folder = "CLZ-250-for-each-windows-vms"; Title = "For Each Windows VMs"; Topic = "Terraform for_each with Windows VMs"; Kind = "foreach-vms"; Focus = "Create named Windows VMs from a map." },
  [ordered]@{ Number = 17; Id = "CLZ-260"; Folder = "CLZ-260-windows-vmss-manual-scaling"; Title = "Windows VMSS Manual Scaling"; Topic = "Windows VMSS with IIS"; Kind = "vmss"; Focus = "Deploy a Windows VMSS and control the instance count." },
  [ordered]@{ Number = 18; Id = "CLZ-270"; Folder = "CLZ-270-windows-vmss-autoscaling"; Title = "Windows VMSS Autoscaling"; Topic = "Autoscale rules and validation"; Kind = "autoscale"; Focus = "Attach CPU-based autoscale rules to the Windows VMSS." },
  [ordered]@{ Number = 19; Id = "CLZ-280"; Folder = "CLZ-280-nat-gateway-outbound"; Title = "NAT Gateway Outbound"; Topic = "NAT Gateway for private Windows workloads"; Kind = "nat-gateway"; Focus = "Give a private subnet stable outbound access." },
  [ordered]@{ Number = 20; Id = "CLZ-290"; Folder = "CLZ-290-private-dns"; Title = "Private DNS"; Topic = "Private DNS zones and internal names"; Kind = "private-dns"; Focus = "Create internal name resolution for private services." },
  [ordered]@{ Number = 21; Id = "CLZ-300"; Folder = "CLZ-300-public-dns-optional"; Title = "Public DNS Optional"; Topic = "Public DNS zone pattern"; Kind = "public-dns"; Focus = "Model a public DNS zone without requiring a delegated domain." },
  [ordered]@{ Number = 22; Id = "CLZ-310"; Folder = "CLZ-310-remote-state-storage"; Title = "Remote State Storage"; Topic = "Azure Storage backend"; Kind = "remote-state"; Focus = "Create the storage account and container used for state." },
  [ordered]@{ Number = 23; Id = "CLZ-320"; Folder = "CLZ-320-cross-environment-state"; Title = "Cross Environment State"; Topic = "Remote state data between environments"; Kind = "remote-state-data"; Focus = "Read outputs from a shared state file." },
  [ordered]@{ Number = 24; Id = "CLZ-330"; Folder = "CLZ-330-traffic-manager-or-front-door"; Title = "Traffic Manager Or Front Door"; Topic = "Global routing for HTTP endpoints"; Kind = "traffic"; Focus = "Use Traffic Manager to route between configurable endpoints." },
  [ordered]@{ Number = 25; Id = "CLZ-340"; Folder = "CLZ-340-key-vault-secrets"; Title = "Key Vault Secrets"; Topic = "Key Vault for generated admin secrets"; Kind = "key-vault"; Focus = "Store generated Windows admin credentials in Key Vault." },
  [ordered]@{ Number = 26; Id = "CLZ-350"; Folder = "CLZ-350-private-endpoint-storage"; Title = "Private Endpoint Storage"; Topic = "Private endpoint and private DNS for Storage"; Kind = "private-endpoint"; Focus = "Expose a storage account through a private endpoint." },
  [ordered]@{ Number = 27; Id = "CLZ-360"; Folder = "CLZ-360-azure-monitor-log-analytics"; Title = "Azure Monitor Log Analytics"; Topic = "Monitoring, alerts, and workspace basics"; Kind = "monitor"; Focus = "Create a Log Analytics workspace and alert action group." },
  [ordered]@{ Number = 28; Id = "CLZ-370"; Folder = "CLZ-370-github-actions-terraform"; Title = "GitHub Actions Terraform"; Topic = "GitHub Actions plan workflow"; Kind = "github-actions"; Focus = "Add an example workflow for Terraform validation and planning." },
  [ordered]@{ Number = 29; Id = "CLZ-380"; Folder = "CLZ-380-azure-sql-private-access"; Title = "Azure SQL Private Access"; Topic = "Azure SQL with private access"; Kind = "azure-sql"; Focus = "Deploy Azure SQL with a private endpoint and private DNS." },
  [ordered]@{ Number = 30; Id = "CLZ-390"; Folder = "CLZ-390-final-windows-reference-architecture"; Title = "Final Windows Reference Architecture"; Topic = "Modules, VMSS, Bastion, Key Vault, and monitoring"; Kind = "capstone"; Focus = "Combine reusable modules into a complete Windows reference environment." }
)

function Get-ArchitectureText {
  param([hashtable]$Lesson)
  switch ($Lesson.Kind) {
    "basic" { "A single tagged Azure resource group keeps the early workflow low cost while the lab user practices Terraform commands." }
    "network" { "A resource group contains one VNet with web, app, data, and management subnets." }
    "security" { "A VNet web subnet is protected by an NSG with HTTP and scoped RDP rules." }
    "windows-vm" { "A Windows Server VM is attached to a web subnet with a public IP for first-access validation." }
    "iis-vm" { "A Windows Server VM uses Custom Script Extension to install IIS and publish a simple page." }
    "bastion" { "Azure Bastion provides browser-based RDP to a private Windows VM." }
    "load-balancer" { "A Standard Load Balancer distributes HTTP traffic to two IIS Windows VMs." }
    "nat-rules" { "A Standard Load Balancer exposes HTTP and one scoped RDP NAT rule for a backend Windows VM." }
    "count-vms" { "Terraform count creates a small set of identical Windows VMs." }
    "foreach-vms" { "Terraform for_each creates named Windows VMs from a map." }
    "vmss" { "A Windows VMSS runs IIS behind a Standard Load Balancer." }
    "autoscale" { "A Windows VMSS adds CPU-based autoscale rules." }
    "nat-gateway" { "A private subnet uses NAT Gateway for stable outbound access." }
    "private-dns" { "A private DNS zone is linked to the VNet and populated with an internal record." }
    "public-dns" { "An optional public DNS zone is controlled by a boolean variable." }
    "remote-state" { "A storage account and private container are prepared for Terraform state." }
    "remote-state-data" { "A data block reads outputs from an Azure Storage-backed state file." }
    "traffic" { "Traffic Manager routes to two configurable endpoint host names." }
    "key-vault" { "Key Vault stores a generated Windows admin password." }
    "private-endpoint" { "A storage account is reached through a private endpoint and private DNS zone." }
    "monitor" { "A Log Analytics workspace and action group create the base monitoring layer." }
    "github-actions" { "A workflow example runs Terraform format, validation, and plan steps." }
    "azure-sql" { "Azure SQL is exposed through a private endpoint and private DNS zone." }
    "capstone" { "Reusable modules create the network, Windows VMSS, Bastion, Key Vault, and monitoring layers." }
  }
}

function Get-FocusFileName {
  param([string]$Kind)
  switch ($Kind) {
    "network" { "network.tf" }
    "security" { "security.tf" }
    "windows-vm" { "compute-windows.tf" }
    "iis-vm" { "compute-windows.tf" }
    "bastion" { "bastion.tf" }
    "load-balancer" { "load-balancer.tf" }
    "nat-rules" { "load-balancer-nat.tf" }
    "count-vms" { "compute-count.tf" }
    "foreach-vms" { "compute-for-each.tf" }
    "vmss" { "vmss.tf" }
    "autoscale" { "autoscale.tf" }
    "nat-gateway" { "nat-gateway.tf" }
    "private-dns" { "private-dns.tf" }
    "public-dns" { "public-dns.tf" }
    "remote-state" { "state-storage.tf" }
    "remote-state-data" { "remote-state-data.tf" }
    "traffic" { "traffic-manager.tf" }
    "key-vault" { "key-vault.tf" }
    "private-endpoint" { "private-endpoint.tf" }
    "monitor" { "monitoring.tf" }
    "github-actions" { "workflow-support.tf" }
    "azure-sql" { "azure-sql.tf" }
    "capstone" { "capstone.tf" }
    default { "lab.tf" }
  }
}

function Get-CommonVariables {
  param([hashtable]$Lesson)
  return @"
variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the active Azure CLI subscription when supported."
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Use dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for this lab."
  type        = string
  default     = "eastus2"
}

variable "lab_id" {
  description = "Azure From Zero To Hero lesson ID."
  type        = string
  default     = "$($Lesson.Id)"
}

variable "name_prefix" {
  description = "Short prefix used in Azure resource names."
  type        = string
  default     = "clz"
}

variable "admin_username" {
  description = "Windows administrator username."
  type        = string
  default     = "clzadmin"
}

variable "admin_cidr" {
  description = "CIDR block allowed for direct RDP examples."
  type        = string
  default     = "203.0.113.10/32"
}

variable "instance_count" {
  description = "Default number of Windows instances for scale examples."
  type        = number
  default     = 2
}

variable "vm_names" {
  description = "Named Windows VM set for for_each examples."
  type        = map(string)
  default = {
    web = "web"
    ops = "ops"
  }
}

variable "create_public_dns_zone" {
  description = "Set true only when you own the DNS zone name."
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Public DNS zone name used when create_public_dns_zone is true."
  type        = string
  default     = "example.com"
}

variable "primary_endpoint_fqdn" {
  description = "Primary endpoint host name for global routing examples."
  type        = string
  default     = "primary.example.com"
}

variable "secondary_endpoint_fqdn" {
  description = "Secondary endpoint host name for global routing examples."
  type        = string
  default     = "secondary.example.com"
}

variable "remote_state_resource_group_name" {
  description = "Resource group that contains the shared state storage account."
  type        = string
  default     = "clz-dev-clz310-rg"
}

variable "remote_state_storage_account_name" {
  description = "Storage account that contains the shared state file."
  type        = string
  default     = "replacewithstateaccount"
}

variable "remote_state_container_name" {
  description = "Storage container that contains the shared state file."
  type        = string
  default     = "tfstate"
}

variable "remote_state_key" {
  description = "State file key to read."
  type        = string
  default     = "clz-dev.tfstate"
}

variable "sql_admin_login" {
  description = "Azure SQL administrator login."
  type        = string
  default     = "clzsqladmin"
}
"@
}

function Get-VersionsTf {
  return @'
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
'@
}

function Get-ProvidersTf {
  return @'
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
'@
}

function Get-LocalsTf {
  return @'
locals {
  lab_number     = replace(var.lab_id, "CLZ-", "")
  lab_code       = lower(replace(var.lab_id, "CLZ-", "clz"))
  prefix         = lower("${var.name_prefix}-${var.environment}-${local.lab_code}")
  compact_prefix = substr(replace(local.prefix, "-", ""), 0, 18)

  tags = {
    Project     = "Azure From Zero To Hero"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Lab         = var.lab_id
  }
}
'@
}

function Get-ResourceGroupTf {
  return @'
resource "azurerm_resource_group" "lab" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.tags
}
'@
}

function Get-NetworkCore {
  return @'
resource "azurerm_virtual_network" "main" {
  name                = "${local.prefix}-vnet"
  address_space       = ["10.40.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

resource "azurerm_subnet" "web" {
  name                 = "web-snet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "app-snet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.2.0/24"]
}

resource "azurerm_subnet" "data" {
  name                 = "data-snet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.3.0/24"]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "mgmt-snet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.10.0/24"]
}
'@
}

function Get-WebNsg {
  return @'
resource "azurerm_network_security_group" "web" {
  name                = "${local.prefix}-web-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "allow_admin_rdp" {
  name                        = "allow-admin-rdp"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.admin_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}
'@
}

function Get-WindowsImage {
  return @'
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
'@
}

function Get-Password {
  return @'
resource "random_password" "windows_admin" {
  length           = 20
  special          = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
'@
}

function Get-PublicIpVm {
  param([switch]$WithIis)

  $extension = if ($WithIis) {
@'

resource "azurerm_virtual_machine_extension" "iis" {
  name                       = "install-iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.web.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value 'Azure From Zero To Hero IIS ${local.prefix}'\""
  })
}
'@
  } else {
    ""
  }

  return (Get-Password) + @'

resource "azurerm_public_ip" "web" {
  name                = "${local.prefix}-web-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "web" {
  name                = "${local.prefix}-web-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }

  tags = local.tags
}

resource "azurerm_windows_virtual_machine" "web" {
  name                = "${local.prefix}-web-winvm"
  computer_name       = "clz${local.lab_number}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = random_password.windows_admin.result
  network_interface_ids = [
    azurerm_network_interface.web.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

'@ + (Get-WindowsImage) + @'

  tags = local.tags
}
'@ + $extension
}

function Get-PrivateVmWithBastion {
  return (Get-Password) + @'

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.main.name
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

resource "azurerm_network_interface" "private_web" {
  name                = "${local.prefix}-private-web-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

resource "azurerm_windows_virtual_machine" "private_web" {
  name                = "${local.prefix}-private-web-winvm"
  computer_name       = "clz${local.lab_number}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = random_password.windows_admin.result
  network_interface_ids = [
    azurerm_network_interface.private_web.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = local.tags
}
'@
}

function Get-LoadBalancerVms {
  param([switch]$WithNatRule)

  $natRule = if ($WithNatRule) {
@'

resource "azurerm_lb_nat_rule" "rdp_first" {
  name                           = "rdp-first-backend"
  resource_group_name            = azurerm_resource_group.lab.name
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 50001
  backend_port                   = 3389
  frontend_ip_configuration_name = "public"
}

resource "azurerm_network_interface_nat_rule_association" "rdp_first" {
  network_interface_id  = azurerm_network_interface.web[0].id
  ip_configuration_name = "internal"
  nat_rule_id           = azurerm_lb_nat_rule.rdp_first.id
}
'@
  } else {
    ""
  }

  return (Get-Password) + @'

resource "azurerm_public_ip" "lb" {
  name                = "${local.prefix}-lb-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_lb" "web" {
  name                = "${local.prefix}-web-lb"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "web-backend-pool"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.web.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "${local.prefix}-web-${count.index + 1}-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

resource "azurerm_windows_virtual_machine" "web" {
  count               = 2
  name                = "${local.prefix}-web-${count.index + 1}-winvm"
  computer_name       = "clz${local.lab_number}${count.index + 1}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = random_password.windows_admin.result
  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = local.tags
}

resource "azurerm_virtual_machine_extension" "iis" {
  count                      = 2
  name                       = "install-iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.web[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value 'Azure From Zero To Hero backend ${count.index + 1}'\""
  })
}
'@ + $natRule
}

function Get-CountVms {
  return (Get-Password) + @'

resource "azurerm_public_ip" "web" {
  count               = var.instance_count
  name                = "${local.prefix}-count-${count.index + 1}-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "web" {
  count               = var.instance_count
  name                = "${local.prefix}-count-${count.index + 1}-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web[count.index].id
  }

  tags = local.tags
}

resource "azurerm_windows_virtual_machine" "web" {
  count               = var.instance_count
  name                = "${local.prefix}-count-${count.index + 1}-winvm"
  computer_name       = "clz${local.lab_number}${count.index + 1}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = random_password.windows_admin.result
  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = local.tags
}
'@
}

function Get-ForEachVms {
  return (Get-Password) + @'

resource "azurerm_public_ip" "web" {
  for_each            = var.vm_names
  name                = "${local.prefix}-${each.key}-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "web" {
  for_each            = var.vm_names
  name                = "${local.prefix}-${each.key}-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web[each.key].id
  }

  tags = local.tags
}

resource "azurerm_windows_virtual_machine" "web" {
  for_each            = var.vm_names
  name                = "${local.prefix}-${each.key}-winvm"
  computer_name       = "clz${local.lab_number}${substr(each.key, 0, 3)}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = random_password.windows_admin.result
  network_interface_ids = [
    azurerm_network_interface.web[each.key].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = local.tags
}
'@
}

function Get-Vmss {
  param([switch]$WithAutoscale)

  $autoscale = if ($WithAutoscale) {
@'

resource "azurerm_monitor_autoscale_setting" "web" {
  name                = "${local.prefix}-vmss-autoscale"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.web.id
  tags                = local.tags

  profile {
    name = "default"

    capacity {
      default = tostring(var.instance_count)
      minimum = "2"
      maximum = "4"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}
'@
  } else {
    ""
  }

  return (Get-Password) + @'

resource "azurerm_public_ip" "lb" {
  name                = "${local.prefix}-vmss-lb-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_lb" "web" {
  name                = "${local.prefix}-vmss-lb"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "vmss-backend-pool"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.web.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_windows_virtual_machine_scale_set" "web" {
  name                = "${local.prefix}-web-vmss"
  computer_name_prefix = "clzwin"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "Standard_B2s"
  instances           = var.instance_count
  admin_username      = var.admin_username
  admin_password      = random_password.windows_admin.result
  upgrade_mode        = "Manual"
  tags                = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  network_interface {
    name    = "web-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.web.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web.id]
    }
  }
}

resource "azurerm_virtual_machine_scale_set_extension" "iis" {
  name                         = "install-iis"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.web.id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.10"
  auto_upgrade_minor_version   = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value 'Azure From Zero To Hero VMSS ${local.prefix}'\""
  })
}
'@ + $autoscale
}

function Get-NatGateway {
  return @'
resource "azurerm_public_ip" "nat" {
  name                = "${local.prefix}-nat-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "main" {
  name                = "${local.prefix}-natgw"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku_name            = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "web" {
  subnet_id      = azurerm_subnet.web.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
'@
}

function Get-PrivateDns {
  return @'
resource "azurerm_private_dns_zone" "internal" {
  name                = "clz.internal"
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal" {
  name                  = "${local.prefix}-vnet-link"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "web" {
  name                = "web"
  zone_name           = azurerm_private_dns_zone.internal.name
  resource_group_name = azurerm_resource_group.lab.name
  ttl                 = 300
  records             = ["10.40.1.10"]
  tags                = local.tags
}
'@
}

function Get-PublicDns {
  return @'
resource "azurerm_dns_zone" "public" {
  count               = var.create_public_dns_zone ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}
'@
}

function Get-RemoteStateStorage {
  return @'
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "state" {
  name                     = substr("st${local.compact_prefix}${random_string.suffix.result}", 0, 24)
  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
'@
}

function Get-RemoteStateData {
  return @'
data "terraform_remote_state" "shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state_resource_group_name
    storage_account_name = var.remote_state_storage_account_name
    container_name       = var.remote_state_container_name
    key                  = var.remote_state_key
  }
}

locals {
  shared_outputs = try(data.terraform_remote_state.shared.outputs, {})
}
'@
}

function Get-TrafficManager {
  return @'
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
'@
}

function Get-KeyVault {
  return (Get-Password) + @'

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "lab" {
  name                       = substr("kv-${local.compact_prefix}", 0, 24)
  location                   = azurerm_resource_group.lab.location
  resource_group_name        = azurerm_resource_group.lab.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = local.tags

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
'@
}

function Get-PrivateEndpointStorage {
  return @'
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "private" {
  name                     = substr("st${local.compact_prefix}${random_string.suffix.result}", 0, 24)
  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "${local.prefix}-blob-link"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "blob" {
  name                = "${local.prefix}-blob-pe"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  subnet_id           = azurerm_subnet.data.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.prefix}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.private.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
'@
}

function Get-Monitoring {
  return @'
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
'@
}

function Get-AzureSql {
  return (Get-Password) + @'

resource "azurerm_mssql_server" "main" {
  name                          = "${local.prefix}-sql"
  resource_group_name           = azurerm_resource_group.lab.name
  location                      = azurerm_resource_group.lab.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = random_password.windows_admin.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = local.tags
}

resource "azurerm_mssql_database" "main" {
  name      = "clzdb"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic"
  tags      = local.tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${local.prefix}-sql-link"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "${local.prefix}-sql-pe"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  subnet_id           = azurerm_subnet.data.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.prefix}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}
'@
}

function Get-Capstone {
  return (Get-Password) + @'

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
  instance_count      = var.instance_count
  tags                = local.tags
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

resource "azurerm_key_vault" "lab" {
  name                       = substr("kv-${local.compact_prefix}", 0, 24)
  location                   = azurerm_resource_group.lab.location
  resource_group_name        = azurerm_resource_group.lab.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = local.tags

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
'@
}

function Get-FocusContent {
  param([hashtable]$Lesson)
  switch ($Lesson.Kind) {
    "network" { Get-NetworkCore }
    "security" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) }
    "windows-vm" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-PublicIpVm) }
    "iis-vm" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-PublicIpVm -WithIis) }
    "bastion" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-PrivateVmWithBastion) }
    "load-balancer" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-LoadBalancerVms) }
    "nat-rules" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-LoadBalancerVms -WithNatRule) }
    "count-vms" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-CountVms) }
    "foreach-vms" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-ForEachVms) }
    "vmss" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-Vmss) }
    "autoscale" { (Get-NetworkCore) + "`r`n" + (Get-WebNsg) + "`r`n" + (Get-Vmss -WithAutoscale) }
    "nat-gateway" { (Get-NetworkCore) + "`r`n" + (Get-NatGateway) }
    "private-dns" { (Get-NetworkCore) + "`r`n" + (Get-PrivateDns) }
    "public-dns" { Get-PublicDns }
    "remote-state" { Get-RemoteStateStorage }
    "remote-state-data" { Get-RemoteStateData }
    "traffic" { Get-TrafficManager }
    "key-vault" { Get-KeyVault }
    "private-endpoint" { (Get-NetworkCore) + "`r`n" + (Get-PrivateEndpointStorage) }
    "monitor" { Get-Monitoring }
    "github-actions" { @'
locals {
  workflow_folder = ".github/workflows"
}
'@ }
    "azure-sql" { (Get-NetworkCore) + "`r`n" + (Get-AzureSql) }
    "capstone" { Get-Capstone }
    default { @'
locals {
  lesson_checkpoint = "Run the Terraform workflow against this resource group."
}
'@ }
  }
}

function Get-OutputsTf {
  param([hashtable]$Lesson)

  $common = @'
output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Azure region used by this lab."
  value       = azurerm_resource_group.lab.location
}
'@

  $extra = switch ($Lesson.Kind) {
    "network" {
@'

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.main.name
}
'@
    }
    "security" {
@'

output "web_nsg_name" {
  description = "Web subnet NSG name."
  value       = azurerm_network_security_group.web.name
}
'@
    }
    "windows-vm" {
@'

output "windows_vm_public_ip" {
  description = "Public IP for first-access validation."
  value       = azurerm_public_ip.web.ip_address
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "iis-vm" {
@'

output "iis_url" {
  description = "IIS validation URL."
  value       = "http://${azurerm_public_ip.web.ip_address}"
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "bastion" {
@'

output "bastion_name" {
  description = "Azure Bastion name."
  value       = azurerm_bastion_host.main.name
}

output "private_windows_vm_id" {
  description = "Private Windows VM ID."
  value       = azurerm_windows_virtual_machine.private_web.id
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "load-balancer" {
@'

output "load_balancer_url" {
  description = "Load balancer validation URL."
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "nat-rules" {
@'

output "load_balancer_public_ip" {
  description = "Load balancer public IP."
  value       = azurerm_public_ip.lb.ip_address
}

output "rdp_nat_port" {
  description = "RDP NAT frontend port."
  value       = 50001
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "count-vms" {
@'

output "windows_vm_public_ips" {
  description = "Public IPs created with count."
  value       = azurerm_public_ip.web[*].ip_address
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "foreach-vms" {
@'

output "windows_vm_public_ips" {
  description = "Public IPs created with for_each."
  value       = { for name, pip in azurerm_public_ip.web : name => pip.ip_address }
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "vmss" {
@'

output "vmss_load_balancer_url" {
  description = "VMSS load balancer validation URL."
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "autoscale" {
@'

output "autoscale_setting_name" {
  description = "Autoscale setting name."
  value       = azurerm_monitor_autoscale_setting.web.name
}

output "vmss_load_balancer_url" {
  description = "VMSS load balancer validation URL."
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "nat-gateway" {
@'

output "nat_gateway_public_ip" {
  description = "NAT Gateway outbound public IP."
  value       = azurerm_public_ip.nat.ip_address
}
'@
    }
    "private-dns" {
@'

output "private_dns_zone_name" {
  description = "Private DNS zone name."
  value       = azurerm_private_dns_zone.internal.name
}
'@
    }
    "public-dns" {
@'

output "public_dns_name_servers" {
  description = "Name servers for the optional public DNS zone."
  value       = var.create_public_dns_zone ? azurerm_dns_zone.public[0].name_servers : []
}
'@
    }
    "remote-state" {
@'

output "state_storage_account_name" {
  description = "Storage account for state."
  value       = azurerm_storage_account.state.name
}

output "state_container_name" {
  description = "Storage container for state."
  value       = azurerm_storage_container.state.name
}
'@
    }
    "remote-state-data" {
@'

output "shared_output_keys" {
  description = "Output keys read from shared state."
  value       = keys(local.shared_outputs)
}
'@
    }
    "traffic" {
@'

output "traffic_manager_fqdn" {
  description = "Traffic Manager DNS name."
  value       = azurerm_traffic_manager_profile.web.fqdn
}
'@
    }
    "key-vault" {
@'

output "key_vault_name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.lab.name
}

output "secret_name" {
  description = "Stored secret name."
  value       = azurerm_key_vault_secret.windows_admin_password.name
}
'@
    }
    "private-endpoint" {
@'

output "storage_account_name" {
  description = "Storage account reached by private endpoint."
  value       = azurerm_storage_account.private.name
}

output "private_endpoint_id" {
  description = "Private endpoint ID."
  value       = azurerm_private_endpoint.blob.id
}
'@
    }
    "monitor" {
@'

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID."
  value       = azurerm_log_analytics_workspace.main.id
}
'@
    }
    "azure-sql" {
@'

output "sql_server_name" {
  description = "Azure SQL server name."
  value       = azurerm_mssql_server.main.name
}

output "sql_admin_password" {
  description = "Generated SQL admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    "capstone" {
@'

output "capstone_load_balancer_url" {
  description = "Capstone VMSS load balancer URL."
  value       = module.windows_iis_vmss.load_balancer_url
}

output "key_vault_name" {
  description = "Capstone Key Vault name."
  value       = azurerm_key_vault.lab.name
}

output "windows_admin_password" {
  description = "Generated Windows admin password."
  value       = random_password.windows_admin.result
  sensitive   = true
}
'@
    }
    default { "" }
  }

  return $common + $extra
}

function Get-TfVarsExample {
  param([hashtable]$Lesson)
  return @"
# Copy to terraform.tfvars for local runs. Keep real values out of commits.
environment     = "dev"
location        = "eastus2"
lab_id          = "$($Lesson.Id)"
name_prefix     = "clz"
admin_username  = "clzadmin"
admin_cidr      = "203.0.113.10/32"
instance_count  = 2
subscription_id = null

# Optional examples used by selected lessons.
create_public_dns_zone             = false
dns_zone_name                      = "example.com"
primary_endpoint_fqdn              = "primary.example.com"
secondary_endpoint_fqdn            = "secondary.example.com"
remote_state_resource_group_name   = "clz-dev-clz310-rg"
remote_state_storage_account_name  = "replacewithstateaccount"
remote_state_container_name        = "tfstate"
remote_state_key                   = "clz-dev.tfstate"
sql_admin_login                    = "clzsqladmin"
"@
}

function Get-LessonReadme {
  param([hashtable]$Lesson)
  $architecture = Get-ArchitectureText -Lesson $Lesson
  $focusFile = Get-FocusFileName -Kind $Lesson.Kind

  return @"
# $($Lesson.Id) - $($Lesson.Title)

## Goal
$($Lesson.Focus)

## Architecture
$architecture

## Prerequisites
- Windows PowerShell 7 or Windows PowerShell 5.1.
- Terraform 1.6 or newer.
- Azure CLI signed in with the target subscription selected.
- Permission to create and delete resources in the selected subscription.

## Files In This Lab
- ``versions.tf`` pins Terraform and provider requirements.
- ``providers.tf`` configures AzureRM.
- ``variables.tf`` defines reusable inputs.
- ``locals.tf`` builds names and tags.
- ``resource-group.tf`` creates the lesson resource group.
- ``$focusFile`` contains the lesson-specific Terraform.
- ``outputs.tf`` exposes validation values.
- ``terraform.tfvars.example`` shows safe example inputs.

## Steps
1. Review ``terraform.tfvars.example`` and create a local ``terraform.tfvars`` if you need to override values.
2. Run ``terraform init``.
3. Run ``terraform fmt -check``.
4. Run ``terraform validate``.
5. Run ``terraform plan -out tfplan``.
6. Run ``terraform apply tfplan`` only when the plan matches the expected resources.

## Validation
- Confirm the resource group name starts with ``clz-dev``.
- Confirm every Azure resource has the standard Azure From Zero To Hero tags.
- Review ``terraform output`` for lesson-specific validation values.

## Cleanup
Run ``terraform destroy`` from this folder when the lab is complete.

## Troubleshooting
- If authentication fails, run ``az account show`` and confirm the expected subscription.
- If names conflict, change ``name_prefix`` or ``environment`` in your local values file.
- If an Azure quota blocks deployment, lower ``instance_count`` or choose another region.
"@
}

function Get-RootReadme {
  $rows = ($Lessons | ForEach-Object { "| $($_.Number) | ``$($_.Folder)`` | $($_.Topic) |" }) -join "`r`n"
  return @"
# Azure From Zero To Hero

Azure From Zero To Hero is an original Windows-focused Azure Terraform curriculum. It uses PowerShell, Windows Server 2022, IIS, Azure Bastion RDP, GitHub Actions, Azure SQL, Key Vault, Private Endpoint, and Azure Monitor.

## Defaults
- Region: ``eastus2``
- Resource prefix: ``clz``
- Environments: ``dev``, ``test``, ``prod``
- Compute pattern: Windows VM and Windows VMSS
- Bootstrap path: PowerShell Custom Script Extension
- State path: Azure Storage backend

## Cost Discipline
Several lessons create paid Azure resources. Run ``terraform destroy`` after each lab unless you are intentionally using its outputs in the next lesson.

## Curriculum
| Lesson | Folder | Topic |
|---:|---|---|
$rows

## Shared References
The ``wiki`` folder contains reusable explanations for Terraform workflow, Azure networking, Windows compute notes, state, security, and troubleshooting.

## Naming And Tags
Each lesson uses names like ``clz-dev-clz100-rg`` and tags every supported resource with:

~~~hcl
Project     = "Azure From Zero To Hero"
Environment = var.environment
ManagedBy   = "Terraform"
Lab         = var.lab_id
~~~

## Standard Run
~~~powershell
terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform destroy
~~~
"@
}

function Get-WikiCore {
  return @'
# Terraform Core Concepts

Terraform compares configuration, state, and real Azure resources to decide what should change.

## Main Commands
- `terraform init` downloads providers and prepares the working folder.
- `terraform fmt` normalizes HCL formatting.
- `terraform validate` checks configuration structure.
- `terraform plan` previews changes.
- `terraform apply` makes approved changes.
- `terraform destroy` removes resources managed by the current state.

## Files
- `versions.tf` pins Terraform and provider requirements.
- `providers.tf` configures providers.
- `variables.tf` defines inputs.
- `locals.tf` centralizes derived names and tags.
- `outputs.tf` exposes useful values after apply.
- `terraform.tfvars.example` is safe to commit; real local values stay private.
'@
}

function Get-WikiNetworking {
  return @'
# Azure Networking Glossary

## Resource Group
A logical container for Azure resources created by one lab.

## Virtual Network
An isolated address space for Azure resources.

## Subnet
A smaller address range inside a VNet. Azure From Zero To Hero uses web, app, data, and management subnets.

## Network Security Group
A rule set that controls inbound and outbound traffic.

## Load Balancer
A layer 4 Azure service that distributes TCP traffic across backend instances.

## Private DNS
An internal DNS zone linked to a VNet for private name resolution.

## Private Endpoint
A private network interface that exposes a platform service inside a VNet.
'@
}

function Get-WikiWindows {
  return @'
# Windows VM And VMSS Notes

## Image Standard
Azure From Zero To Hero uses Windows Server 2022 Azure Edition by default.

## Access
Early labs may use scoped RDP for learning. Later labs prefer Azure Bastion so Windows VMs do not need public IPs.

## Bootstrap
IIS examples use PowerShell through Custom Script Extension. The validation page is written to `C:\inetpub\wwwroot\index.html`.

## Credentials
Labs generate passwords with `random_password` and mark password outputs as sensitive. Key Vault is introduced before the capstone.
'@
}

function Get-WikiState {
  return @'
# State Backend And Locking

Terraform state maps configuration to Azure resource IDs. Treat state as operational data.

## Local State
Early lessons use local state because it is easier to understand.

## Remote State
The remote state lesson creates an Azure Storage account and private container. Later lessons can read shared outputs with `terraform_remote_state`.

## Safety Rules
- Do not commit state files.
- Do not edit state manually.
- Use a separate state key per environment.
- Destroy lab resources from the same folder that created them.
'@
}

function Get-WikiSecurity {
  return @'
# Security And Secrets

## Passwords
Generated passwords are marked sensitive. Do not put real passwords in committed files.

## Network Access
Use narrow CIDR ranges for admin access. Prefer Bastion for private RDP once the Bastion lesson is complete.

## Key Vault
Key Vault stores generated admin credentials in later lessons. The capstone keeps the same pattern.

## Private Access
Private Endpoint lessons move storage and database access onto the VNet.
'@
}

function Get-WikiTroubleshooting {
  return @'
# Troubleshooting

## Authentication
Run `az account show` to confirm the active subscription. Set `subscription_id` in local values if the provider needs it explicitly.

## Provider Setup
Run `terraform init` again after changing provider versions, modules, or backend settings.

## Naming Conflicts
Some Azure names must be globally unique. Change `name_prefix` or `environment` if Azure reports a conflict.

## Quota
If a VM size is unavailable, change the size in the lesson file or choose another region.

## Cleanup
If destroy fails, rerun `terraform destroy`. Review the Azure portal for resources with the matching `Lab` tag.
'@
}

function Get-InitScript {
  return @'
param()

$ErrorActionPreference = "Stop"

$tools = @("terraform", "az", "git")
foreach ($tool in $tools) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if (-not $cmd) {
    throw "$tool was not found on PATH."
  }
  Write-Host "$tool found at $($cmd.Source)"
}

terraform version
az version --output table
git --version
'@
}

function Get-TestScript {
  return @'
param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$Validate
)

$ErrorActionPreference = "Stop"

Push-Location $Root
try {
  terraform fmt -check -recursive

  if ($Validate) {
    Get-ChildItem -Directory -Filter "CLZ-*" | ForEach-Object {
      Push-Location $_.FullName
      try {
        terraform init -backend=false -input=false
        terraform validate
      }
      finally {
        Pop-Location
      }
    }
  }
}
finally {
  Pop-Location
}
'@
}

function Get-CleanupScript {
  return @'
param(
  [Parameter(Mandatory = $true)][string]$LabFolder
)

$ErrorActionPreference = "Stop"

$target = Resolve-Path $LabFolder
Push-Location $target
try {
  terraform destroy
}
finally {
  Pop-Location
}
'@
}

function Get-NetworkModuleMain {
  return @'
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.40.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "web" {
  name                 = "web-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_subnet" "data" {
  name                 = "data-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.3.0/24"]
}
'@
}

function Get-NetworkModuleVariables {
  return @'
variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}
'@
}

function Get-NetworkModuleOutputs {
  return @'
output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "web_subnet_id" {
  value = azurerm_subnet.web.id
}

output "data_subnet_id" {
  value = azurerm_subnet.data.id
}
'@
}

function Get-VmssModuleMain {
  return @'
resource "azurerm_public_ip" "lb" {
  name                = "${var.prefix}-vmss-lb-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "web" {
  name                = "${var.prefix}-vmss-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "vmss-backend-pool"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.web.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_windows_virtual_machine_scale_set" "web" {
  name                 = "${var.prefix}-web-vmss"
  computer_name_prefix = "clzwin"
  location             = var.location
  resource_group_name  = var.resource_group_name
  sku                  = "Standard_B2s"
  instances            = var.instance_count
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  upgrade_mode         = "Manual"
  tags                 = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  network_interface {
    name    = "web-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web.id]
    }
  }
}

resource "azurerm_virtual_machine_scale_set_extension" "iis" {
  name                         = "install-iis"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.web.id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.10"
  auto_upgrade_minor_version   = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value 'Azure From Zero To Hero capstone VMSS'\""
  })
}
'@
}

function Get-VmssModuleVariables {
  return @'
variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "instance_count" {
  type = number
}

variable "tags" {
  type = map(string)
}
'@
}

function Get-VmssModuleOutputs {
  return @'
output "load_balancer_url" {
  value = "http://${azurerm_public_ip.lb.ip_address}"
}

output "vmss_id" {
  value = azurerm_windows_virtual_machine_scale_set.web.id
}
'@
}

function Get-GithubWorkflow {
  return @'
name: terraform-plan

on:
  workflow_dispatch:
  pull_request:
    paths:
      - "**"

permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    runs-on: windows-latest
    defaults:
      run:
        shell: pwsh
        working-directory: "CLZ-370-github-actions-terraform"

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init -backend=false

      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -input=false
'@
}

Write-LabFile -RelativePath "README.md" -Content (Get-RootReadme)
Write-LabFile -RelativePath "wiki/terraform-core-concepts.md" -Content (Get-WikiCore)
Write-LabFile -RelativePath "wiki/azure-networking-glossary.md" -Content (Get-WikiNetworking)
Write-LabFile -RelativePath "wiki/windows-vm-and-vmss-notes.md" -Content (Get-WikiWindows)
Write-LabFile -RelativePath "wiki/state-backend-and-locking.md" -Content (Get-WikiState)
Write-LabFile -RelativePath "wiki/security-and-secrets.md" -Content (Get-WikiSecurity)
Write-LabFile -RelativePath "wiki/troubleshooting.md" -Content (Get-WikiTroubleshooting)

Write-LabFile -RelativePath "scripts/Initialize-AzureFromZeroToHeroWorkspace.ps1" -Content (Get-InitScript)
Write-LabFile -RelativePath "scripts/Test-AzureFromZeroToHeroTerraform.ps1" -Content (Get-TestScript)
Write-LabFile -RelativePath "scripts/Invoke-AzureFromZeroToHeroCleanup.ps1" -Content (Get-CleanupScript)

Write-LabFile -RelativePath "modules/README.md" -Content "# Azure From Zero To Hero Modules`r`n`r`nReusable modules are introduced by the capstone lesson. They stay small so each lab user can read every resource."
Write-LabFile -RelativePath "modules/network-core/main.tf" -Content (Get-NetworkModuleMain)
Write-LabFile -RelativePath "modules/network-core/variables.tf" -Content (Get-NetworkModuleVariables)
Write-LabFile -RelativePath "modules/network-core/outputs.tf" -Content (Get-NetworkModuleOutputs)
Write-LabFile -RelativePath "modules/windows-iis-vmss/main.tf" -Content (Get-VmssModuleMain)
Write-LabFile -RelativePath "modules/windows-iis-vmss/variables.tf" -Content (Get-VmssModuleVariables)
Write-LabFile -RelativePath "modules/windows-iis-vmss/outputs.tf" -Content (Get-VmssModuleOutputs)

foreach ($lesson in $Lessons) {
  $folder = $lesson.Folder
  Write-LabFile -RelativePath "$folder/README.md" -Content (Get-LessonReadme -Lesson $lesson)
  Write-LabFile -RelativePath "$folder/versions.tf" -Content (Get-VersionsTf)
  Write-LabFile -RelativePath "$folder/providers.tf" -Content (Get-ProvidersTf)
  Write-LabFile -RelativePath "$folder/variables.tf" -Content (Get-CommonVariables -Lesson $lesson)
  Write-LabFile -RelativePath "$folder/locals.tf" -Content (Get-LocalsTf)
  Write-LabFile -RelativePath "$folder/resource-group.tf" -Content (Get-ResourceGroupTf)
  Write-LabFile -RelativePath "$folder/$(Get-FocusFileName -Kind $lesson.Kind)" -Content (Get-FocusContent -Lesson $lesson)
  Write-LabFile -RelativePath "$folder/outputs.tf" -Content (Get-OutputsTf -Lesson $lesson)
  Write-LabFile -RelativePath "$folder/terraform.tfvars.example" -Content (Get-TfVarsExample -Lesson $lesson)

  if ($lesson.Kind -eq "github-actions") {
    Write-LabFile -RelativePath "$folder/.github/workflows/terraform-plan.yml.example" -Content (Get-GithubWorkflow)
  }
}

Write-Host "Azure From Zero To Hero scaffold created at $Root"
