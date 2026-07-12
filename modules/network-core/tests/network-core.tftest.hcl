mock_provider "azurerm" {}

run "builds_expected_network" {
  command = plan

  variables {
    resource_group_name = "clz-test-rg"
    location            = "westeurope"
    prefix              = "clz-test"
    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = azurerm_virtual_network.main.name == "clz-test-vnet"
    error_message = "The virtual network name must be derived from prefix."
  }

  assert {
    condition     = toset(azurerm_subnet.web.address_prefixes) == toset(["10.40.1.0/24"])
    error_message = "The web subnet address space changed unexpectedly."
  }

  assert {
    condition     = toset(azurerm_subnet.data.address_prefixes) == toset(["10.40.3.0/24"])
    error_message = "The data subnet address space changed unexpectedly."
  }
}
