variable "resource_group_name" {
  description = "Resource group where the network resources are created."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be 1 to 90 characters."
  }
}

variable "location" {
  description = "Azure region for the network resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as eastus2."
  }
}

variable "prefix" {
  description = "Name prefix used for network resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,40}$", var.prefix))
    error_message = "prefix must start with a lowercase letter and contain lowercase letters, numbers, or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must include at least one tag."
  }
}

