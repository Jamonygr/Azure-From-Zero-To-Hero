variable "resource_group_name" {
  description = "Resource group where the VMSS resources are created."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be 1 to 90 characters."
  }
}

variable "location" {
  description = "Azure region for the VMSS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as eastus2."
  }
}

variable "prefix" {
  description = "Name prefix used for VMSS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,40}$", var.prefix))
    error_message = "prefix must start with a lowercase letter and contain lowercase letters, numbers, or hyphens."
  }
}

variable "subnet_id" {
  description = "Subnet ID used by VMSS instances."
  type        = string
}

variable "admin_username" {
  description = "Windows administrator username."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_-]{2,19}$", var.admin_username)) && !contains(["administrator", "admin", "user", "guest"], lower(var.admin_username))
    error_message = "admin_username must be 3 to 20 characters, start with a letter, and not use a reserved Windows name."
  }
}

variable "admin_password" {
  description = "Windows administrator password."
  type        = string
  sensitive   = true
}

variable "instance_count" {
  description = "Number of VMSS instances."
  type        = number

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 5
    error_message = "instance_count must be between 1 and 5 for this lab curriculum."
  }
}

variable "tags" {
  description = "Tags applied to VMSS resources."
  type        = map(string)

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must include at least one tag."
  }
}

variable "site_message" {
  description = "Message written to the IIS default page."
  type        = string
  default     = "Azure From Zero To Hero VMSS"

  validation {
    condition     = length(trimspace(var.site_message)) > 0
    error_message = "site_message must not be empty."
  }
}

