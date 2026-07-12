output "configuration_preview" {
  description = "Credential-free preview of values that later lessons use for Azure resources."
  value = {
    resource_group_name = "${local.prefix}-rg"
    location            = var.location
    tags                = local.tags
  }
}

output "terraform_workflow" {
  description = "Safe Terraform commands for this credential-free lesson."
  value = [
    "terraform fmt -check",
    "terraform init",
    "terraform validate",
    "terraform plan",
  ]
}
