output "required_commands" {
  description = "Commands that should work from PowerShell before starting CLZ-100."
  value       = local.required_commands
}

output "recommended_extensions" {
  description = "VS Code extensions recommended for the Chriz Labz workflow."
  value       = local.recommended_extensions
}

output "workstation_profile" {
  description = "Human-readable workstation profile for this optional setup lab."
  value = {
    os              = var.workstation_os
    preferred_shell = var.preferred_shell
    editor          = var.editor
  }
}

output "next_lesson" {
  description = "Next lesson after this optional setup lab."
  value       = "CLZ-100-foundations"
}
