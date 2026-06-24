variable "workstation_os" {
  description = "Expected workstation operating system for this optional lab."
  type        = string
  default     = "Windows"

  validation {
    condition     = var.workstation_os == "Windows"
    error_message = "This curriculum is intentionally Windows-focused."
  }
}

variable "preferred_shell" {
  description = "Preferred shell for running Azure From Zero To Hero commands."
  type        = string
  default     = "PowerShell"

  validation {
    condition     = contains(["PowerShell", "PowerShell 7", "pwsh"], var.preferred_shell)
    error_message = "Use PowerShell, PowerShell 7, or pwsh for the documented command path."
  }
}

variable "editor" {
  description = "Preferred editor for the lab."
  type        = string
  default     = "Visual Studio Code"

  validation {
    condition     = length(trimspace(var.editor)) > 0
    error_message = "editor must not be empty."
  }
}
