variable "workstation_os" {
  description = "Expected workstation operating system for this optional lab."
  type        = string
  default     = "Windows"
}

variable "preferred_shell" {
  description = "Preferred shell for running Chriz Labz commands."
  type        = string
  default     = "PowerShell"
}

variable "editor" {
  description = "Preferred editor for the lab."
  type        = string
  default     = "Visual Studio Code"
}
