variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use ARM_SUBSCRIPTION_ID or another supported authentication source."
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
    error_message = "environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for this lesson."
  type        = string
  default     = "eastus2"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as eastus2, westeurope, or swedencentral."
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

variable "admin_cidr" {
  description = "Single public IPv4 /32 allowed to reach the RDP teaching rule."
  type        = string
  default     = "203.0.113.10/32"
  nullable    = false

  validation {
    condition = try(
      can(cidrhost(var.admin_cidr, 0)) &&
      !strcontains(split("/", var.admin_cidr)[0], ":") &&
      tonumber(split("/", var.admin_cidr)[1]) == 32,
      false
    )
    error_message = "admin_cidr must be one valid public IPv4 /32. Broad ranges, IPv6, and wildcard sources are rejected."
  }
}
