mock_provider "azurerm" {}

override_data {
  target = data.terraform_remote_state.shared
  values = {
    outputs = {}
  }
}

run "rejects_placeholder_remote_state" {
  command = plan

  variables {
    remote_state = {
      resource_group_name  = "clz-state-rg"
      storage_account_name = "placeholder"
      container_name       = "tfstate"
      key                  = "shared.tfstate"
    }
  }

  expect_failures = [var.remote_state]
}
