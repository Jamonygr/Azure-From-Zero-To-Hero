output "readiness_commands" {
  description = "Azure CLI commands to run manually from PowerShell; Terraform itself remains credential-free."
  value       = local.readiness_commands
}

output "subscription_source" {
  description = "Whether the checks use the active Azure CLI context or an explicitly selected subscription."
  value       = var.subscription_id == null ? "active Azure CLI subscription" : "explicit subscription_id input"
}

output "deployment_behavior" {
  description = "Confirms the safety boundary for this lesson."
  value       = "${local.lab_id} declares no providers and deploys no Azure resources."
}
