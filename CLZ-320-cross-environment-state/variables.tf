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

variable "remote_state" {
  description = "Required azurerm backend coordinates produced by CLZ-310."
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
  })

  validation {
    condition = (
      length(trimspace(var.remote_state.resource_group_name)) > 0 &&
      length(var.remote_state.resource_group_name) <= 90 &&
      can(regex("^[a-z0-9]{3,24}$", var.remote_state.storage_account_name)) &&
      !startswith(lower(var.remote_state.storage_account_name), "replace") &&
      !contains(["example", "placeholder", "changeme"], lower(var.remote_state.storage_account_name)) &&
      can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.remote_state.container_name)) &&
      length(trimspace(var.remote_state.key)) > 0 &&
      !startswith(var.remote_state.key, "/")
    )
    error_message = "remote_state must contain real CLZ-310 backend coordinates; placeholder account names and invalid container/key values are rejected."
  }
}
