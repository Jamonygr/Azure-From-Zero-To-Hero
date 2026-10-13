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
  description = "Azure region for this lesson."
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

variable "backend_access_cidr" {
  description = "One public IPv4 address in /32 notation allowed to reach the state storage account."
  type        = string

  validation {
    condition = (
      can(cidrhost(var.backend_access_cidr, 0)) &&
      can(regex("^[0-9.]+/32$", var.backend_access_cidr)) &&
      !startswith(var.backend_access_cidr, "0.0.0.0/")
    )
    error_message = "backend_access_cidr must be one public IPv4 address in /32 notation, for example 203.0.113.10/32."
  }
}
