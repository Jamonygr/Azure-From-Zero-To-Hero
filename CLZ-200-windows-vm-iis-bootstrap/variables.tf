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
  default     = "CLZ-200"
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

