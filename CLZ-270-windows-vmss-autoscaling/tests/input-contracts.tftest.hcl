mock_provider "azurerm" {}
mock_provider "random" {}

run "accepts_ordered_autoscale_capacity" {
  command = plan

  variables {
    autoscale_capacity = {
      minimum = 1
      default = 2
      maximum = 4
    }
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.web.profile[0].capacity[0].minimum == 1
    error_message = "Autoscale minimum must match the typed capacity object."
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.web.profile[0].capacity[0].default == 2
    error_message = "Autoscale default must match the typed capacity object."
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.web.profile[0].capacity[0].maximum == 4
    error_message = "Autoscale maximum must match the typed capacity object."
  }
}

run "rejects_invalid_autoscale_order" {
  command = plan

  variables {
    autoscale_capacity = {
      minimum = 3
      default = 2
      maximum = 4
    }
  }

  expect_failures = [var.autoscale_capacity]
}
