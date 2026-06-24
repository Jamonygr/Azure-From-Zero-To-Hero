variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the active Azure CLI subscription when supported."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.subscription_id == null ? true : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be null or a valid Azure subscription GUID."
  }
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

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as eastus2, westeurope, or swedencentral."
  }
}

variable "lab_id" {
  description = "Azure From Zero To Hero lesson ID."
  type        = string
  default     = "CLZ-210"

  validation {
    condition     = can(regex("^CLZ-[0-9]{3}$", var.lab_id))
    error_message = "lab_id must use the CLZ-000 format."
  }
}

variable "name_prefix" {
  description = "Short prefix used in Azure resource names."
  type        = string
  default     = "clz"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.name_prefix))
    error_message = "name_prefix must be 2 to 8 lowercase letters or numbers and start with a letter."
  }
}

variable "admin_username" {
  description = "Windows administrator username."
  type        = string
  default     = "clzadmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_-]{2,19}$", var.admin_username)) && !contains(["administrator", "admin", "user", "guest"], lower(var.admin_username))
    error_message = "admin_username must be 3 to 20 characters, start with a letter, and not use a reserved Windows name."
  }
}

variable "admin_cidr" {
  description = "CIDR block allowed for direct RDP examples."
  type        = string
  default     = "203.0.113.10/32"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block such as 203.0.113.10/32."
  }
}

variable "instance_count" {
  description = "Default number of Windows instances for scale examples."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 5
    error_message = "instance_count must be between 1 and 5 for this lab curriculum."
  }
}

variable "vm_names" {
  description = "Named Windows VM set for for_each examples."
  type        = map(string)
  default = {
    web = "web"
    ops = "ops"
  }

  validation {
    condition = length(var.vm_names) > 0 && alltrue([
      for key, value in var.vm_names :
      can(regex("^[a-z][a-z0-9-]{1,15}$", key)) && can(regex("^[a-z][a-z0-9-]{1,15}$", value))
    ])
    error_message = "vm_names keys and values must be 2 to 16 lowercase letters, numbers, or hyphens and start with a letter."
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

  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?([.][A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$", var.dns_zone_name))
    error_message = "dns_zone_name must be a valid DNS name such as example.com."
  }
}

variable "primary_endpoint_fqdn" {
  description = "Primary endpoint host name for global routing examples."
  type        = string
  default     = "primary.example.com"

  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?([.][A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$", var.primary_endpoint_fqdn))
    error_message = "primary_endpoint_fqdn must be a valid fully qualified domain name."
  }
}

variable "secondary_endpoint_fqdn" {
  description = "Secondary endpoint host name for global routing examples."
  type        = string
  default     = "secondary.example.com"

  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?([.][A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$", var.secondary_endpoint_fqdn))
    error_message = "secondary_endpoint_fqdn must be a valid fully qualified domain name."
  }
}

variable "remote_state_resource_group_name" {
  description = "Resource group that contains the shared state storage account."
  type        = string
  default     = "clz-dev-clz310-rg"

  validation {
    condition     = length(trimspace(var.remote_state_resource_group_name)) > 0 && length(var.remote_state_resource_group_name) <= 90
    error_message = "remote_state_resource_group_name must be 1 to 90 characters."
  }
}

variable "remote_state_storage_account_name" {
  description = "Storage account that contains the shared state file."
  type        = string
  default     = "replacewithstateaccount"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.remote_state_storage_account_name))
    error_message = "remote_state_storage_account_name must be 3 to 24 lowercase letters or numbers."
  }
}

variable "remote_state_container_name" {
  description = "Storage container that contains the shared state file."
  type        = string
  default     = "tfstate"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.remote_state_container_name))
    error_message = "remote_state_container_name must be a valid Azure Storage container name."
  }
}

variable "remote_state_key" {
  description = "State file key to read."
  type        = string
  default     = "clz-dev.tfstate"

  validation {
    condition     = length(trimspace(var.remote_state_key)) > 0 && !startswith(var.remote_state_key, "/")
    error_message = "remote_state_key must be a non-empty relative state key."
  }
}

variable "sql_admin_login" {
  description = "Azure SQL administrator login."
  type        = string
  default     = "clzsqladmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{2,31}$", var.sql_admin_login)) && !contains(["admin", "administrator", "sa", "root", "guest", "dbo"], lower(var.sql_admin_login))
    error_message = "sql_admin_login must be 3 to 32 characters, start with a letter, and avoid reserved administrator names."
  }
}
