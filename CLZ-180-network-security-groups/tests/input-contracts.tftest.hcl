mock_provider "azurerm" {}

run "accepts_narrow_admin_cidr" {
  command = plan

  variables {
    admin_cidr = "203.0.113.10/32"
  }

  assert {
    condition     = azurerm_network_security_rule.allow_admin_rdp.source_address_prefix == "203.0.113.10/32"
    error_message = "The RDP rule must use the explicitly supplied narrow CIDR."
  }

  assert {
    condition = (
      azurerm_network_security_rule.deny_other_rdp.priority == 120 &&
      azurerm_network_security_rule.deny_other_rdp.access == "Deny" &&
      azurerm_network_security_rule.deny_other_rdp.destination_port_range == "3389"
    )
    error_message = "Unmatched RDP must be denied before Azure's default AllowVNetInBound rule."
  }
}

run "rejects_broad_admin_cidr" {
  command = plan

  variables {
    admin_cidr = "0.0.0.0/0"
  }

  expect_failures = [var.admin_cidr]
}

run "rejects_ipv6_admin_cidr" {
  command = plan

  variables {
    admin_cidr = "2001:db8::1/128"
  }

  expect_failures = [var.admin_cidr]
}

run "rejects_multi_address_ipv4_cidr" {
  command = plan

  variables {
    admin_cidr = "203.0.113.0/25"
  }

  expect_failures = [var.admin_cidr]
}
