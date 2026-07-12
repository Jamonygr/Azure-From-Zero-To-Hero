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
  description = "Single public IPv4 /32 allowed to reach RDP."
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

variable "vm_definitions" {
  description = "Named Windows VMs, with a VM size and role for each for_each key."
  type = map(object({
    vm_size = string
    role    = string
  }))
  default = {
    web = {
      vm_size = "Standard_B2s"
      role    = "web"
    }
    ops = {
      vm_size = "Standard_B2s"
      role    = "operations"
    }
  }

  validation {
    condition = length(var.vm_definitions) > 0 && length(var.vm_definitions) <= 5 && alltrue([
      for name, definition in var.vm_definitions :
      can(regex("^[a-z][a-z0-9-]{1,15}$", name)) &&
      can(regex("^Standard_[A-Za-z0-9_]+$", definition.vm_size)) &&
      can(regex("^[a-z][a-z0-9-]{1,19}$", definition.role))
    ])
    error_message = "vm_definitions must contain 1 to 5 entries; keys and roles must use short lowercase names, and vm_size must resemble Standard_B2s."
  }
}
