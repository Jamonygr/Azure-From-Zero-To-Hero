mock_provider "azurerm" {}

run "allows_reserved_name_when_creation_is_disabled" {
  command = plan

  variables {
    create_public_dns_zone = false
    dns_zone_name          = "example.com"
  }

  assert {
    condition     = length(azurerm_dns_zone.public) == 0
    error_message = "The opt-in DNS resource must remain absent by default."
  }
}

run "rejects_reserved_name_when_creation_is_enabled" {
  command = plan

  variables {
    create_public_dns_zone = true
    dns_zone_name          = "example.com"
  }

  expect_failures = [check.owned_public_dns_zone]
}
