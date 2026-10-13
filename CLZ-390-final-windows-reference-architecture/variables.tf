variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the active Azure CLI subscription."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be null or a valid Azure subscription GUID."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for the capstone."
  type        = string
  default     = "eastus2"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as eastus2."
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
  description = "Windows administrator username used through Azure Bastion."
  type        = string
  default     = "clzadmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_-]{2,19}$", var.admin_username)) && !contains(["administrator", "admin", "user", "guest"], lower(var.admin_username))
    error_message = "admin_username must be 3 to 20 characters, start with a letter, and not use a reserved Windows name."
  }
}

variable "vm_size" {
  description = "Azure VM size used by the capstone scale set."
  type        = string
  default     = "Standard_B2s"

  validation {
    condition     = can(regex("^Standard_[A-Za-z0-9_]+$", var.vm_size))
    error_message = "vm_size must be an Azure size name such as Standard_B2s."
  }
}

variable "instance_count" {
  description = "Number of Windows instances in the capstone scale set."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 5 && floor(var.instance_count) == var.instance_count
    error_message = "instance_count must be a whole number from 1 through 5."
  }
}

variable "key_vault_access_cidr" {
  description = "One public IPv4 address in /32 notation allowed to manage the capstone Key Vault."
  type        = string

  validation {
    condition = (
      can(cidrhost(var.key_vault_access_cidr, 0)) &&
      can(regex("^[0-9.]+/32$", var.key_vault_access_cidr)) &&
      !startswith(var.key_vault_access_cidr, "0.0.0.0/")
    )
    error_message = "key_vault_access_cidr must be one public IPv4 address in /32 notation, for example 203.0.113.10/32."
  }
}
