data "terraform_remote_state" "shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state.resource_group_name
    storage_account_name = var.remote_state.storage_account_name
    container_name       = var.remote_state.container_name
    key                  = var.remote_state.key
    use_azuread_auth     = true
  }
}

locals {
  shared_outputs = try(data.terraform_remote_state.shared.outputs, {})
}

