variable "subscription_id" {
  description = "Optional Azure subscription ID to select during the readiness checks."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.subscription_id == null ? true : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be null or a valid Azure subscription GUID."
  }
}

variable "location" {
  description = "Azure region to inspect for VM quota readiness."
  type        = string
  default     = "eastus2"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as eastus2, westeurope, or swedencentral."
  }
}
