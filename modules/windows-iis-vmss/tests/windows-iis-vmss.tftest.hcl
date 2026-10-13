mock_provider "azurerm" {}

variables {
  resource_group_name = "clz-test-rg"
  location            = "westeurope"
  prefix              = "clz-test"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/clz-test-rg/providers/Microsoft.Network/virtualNetworks/clz-test-vnet/subnets/web-snet"
  admin_username      = "clzadmin"
  admin_password      = "Mock-Only-Password-123!"
  vm_size             = "Standard_B2s"
  instance_count      = 2
  tags = {
    Environment = "test"
  }
}

run "configures_vmss_and_explicit_outbound" {
  command = plan

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.web.sku == "Standard_B2s"
    error_message = "The VMSS must use the requested VM size."
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.web.instances == 2
    error_message = "The VMSS must use the requested whole-number instance count."
  }

  assert {
    condition     = azurerm_lb_rule.http.disable_outbound_snat
    error_message = "The inbound HTTP rule must not perform outbound SNAT."
  }

  assert {
    condition     = azurerm_lb_outbound_rule.web.protocol == "All"
    error_message = "The module must retain its explicit Load Balancer outbound rule."
  }
}

run "rejects_fractional_instance_count" {
  command = plan

  variables {
    instance_count = 1.5
  }

  expect_failures = [var.instance_count]
}

run "encodes_site_message_before_powershell" {
  command = plan

  variables {
    site_message = "Hero's site; Write-Host unsafe"
  }

  assert {
    condition = (
      strcontains(jsondecode(azurerm_virtual_machine_scale_set_extension.iis.settings).commandToExecute, base64encode(var.site_message)) &&
      !strcontains(jsondecode(azurerm_virtual_machine_scale_set_extension.iis.settings).commandToExecute, var.site_message)
    )
    error_message = "The IIS message must be base64-encoded before it enters the PowerShell command."
  }
}
