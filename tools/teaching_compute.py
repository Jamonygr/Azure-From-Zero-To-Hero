"""Original, source-linked teaching scenes for the Windows compute lessons.

These diagrams explain selected relationships rather than duplicating the full
architecture inventory. The shared renderer supplies the header and footer.
Every scene declares its own arrow semantics and preserves the lesson's actual
deployment scope, including absent IIS bootstrap and Manual VMSS upgrades.
"""


def vm_components(draw, item):
    """CLZ-190: a VM depends on networking, an OS disk, and credentials."""
    draw.group("Web subnet: 10.40.1.0/24", 285, 365, 585, 260)
    draw.node("public", "Standard public IP", "cloud", 320, 170, 220, 165,
              detail="Direct teaching access")
    draw.node("password", "Generated password", "key", 625, 170, 220, 165,
              detail="Sensitive Terraform state")
    draw.node("nsg", "Web NSG", "shield", 40, 420, 200, 165,
              detail="RDP: admin IPv4 /32")
    draw.node("nic", "NIC", "network", 320, 420, 220, 165,
              detail="Dynamic private address")
    draw.node("vm", "Windows Server 2022", "windows", 625, 420, 220, 165,
              detail="One VM; selected vm_size")
    draw.node("disk", "Managed OS disk", "storage", 945, 420, 220, 165,
              detail="Standard_LRS")
    draw.edge("public", "nic", "Public IP binding", label_pos=(430, 370))
    draw.edge("password", "vm", "Admin credential", label_pos=(735, 370))
    draw.edge("nsg", "nic", "NSG", label_pos=(280, 465))
    draw.edge("nic", "vm", "Attach", label_pos=(582, 465))
    draw.edge("vm", "disk", "OS disk", label_pos=(895, 465))
    draw.note("Solid arrows = deployed component relationships, not packet routes. "
              "The NSG scopes TCP 3389 to admin_cidr; this lesson does not install IIS.")


def iis_bootstrap(draw, item):
    """CLZ-200: extension configuration, guest execution, and HTTP evidence."""
    draw.node("terraform", "Terraform settings", "tf", 45, 245, 245, 185,
              detail="Custom Script Extension")
    draw.node("script", "PowerShell bootstrap", "terminal", 460, 245, 245, 185,
              detail="Install + write page")
    draw.node("iis", "Windows VM + IIS", "windows", 905, 245, 245, 185,
              detail="Web-Server; index.html")
    draw.node("inspect", "Verify the response", "search", 460, 475, 245, 150,
              detail="HTTP 200 + lesson text")
    draw.edge("terraform", "script", "Configure command", label_pos=(375, 235))
    draw.edge("script", "iis", "Execute in guest", label_pos=(805, 310))
    draw.edge("inspect", "iis", "GET public IP:80", style="dotted",
              points=[(820, 550), (1027, 550)], label_pos=(850, 585))
    draw.text("1. Provision extension", 65, 205, size=25, width=24)
    draw.text("2. Install IIS + page", 475, 205, size=25, width=24)
    draw.text("3. Check HTTP", 905, 205, size=25, width=20)
    draw.note("Solid arrows = deployed bootstrap sequence; dotted arrow = learner HTTP check. "
              "Extension Succeeded and a correct HTTP body are separate pieces of evidence.")


def bastion_connection(draw, item):
    """CLZ-210: the browser and private RDP connection are different legs."""
    draw.group("AzureBastionSubnet", 405, 180, 355, 410)
    draw.text("10.40.20.0/26", 580, 245, size=24, width=22, anchor="middle")
    draw.group("Web subnet + VM NSG", 850, 280, 325, 325)
    draw.node("browser", "Administrator browser", "terminal", 35, 340, 235, 180,
              detail="Azure portal session")
    draw.node("bastion", "Azure Bastion", "bastion", 455, 305, 255, 190,
              detail="Standard public IP")
    draw.node("private", "Private Windows VM", "windows", 895, 355, 235, 180,
              detail="NIC has no public IP")
    draw.edge("browser", "bastion", "HTTPS 443", label_pos=(360, 355))
    draw.edge("bastion", "private", "Private TCP 3389", label_pos=(800, 390))
    draw.text("Leg 1: browser → Bastion", 35, 230, size=25, width=25)
    draw.text("Leg 2: Bastion → VM", 850, 210, size=25, width=24)
    draw.note("Solid arrows = the two connection legs. The VM NSG permits RDP from the Bastion "
              "subnet and denies other RDP sources; the VM itself has no direct public RDP endpoint.")


def load_balancer_paths(draw, item):
    """CLZ-220: load balancing, health probes, and egress are independent."""
    draw.node("client", "Web client", "terminal", 40, 190, 220, 165,
              detail="Public frontend: TCP 80")
    draw.node("internet", "Internet destination", "cloud", 40, 460, 220, 165,
              detail="Outbound connections")
    draw.node("lb", "Standard Load Balancer", "loadbalancer", 370, 315, 240, 190,
              detail="One public frontend")
    draw.node("vm0", "IIS backend web[0]", "windows", 915, 190, 240, 165,
              detail="Private NIC; TCP 80")
    draw.node("vm1", "IIS backend web[1]", "windows", 915, 460, 240, 165,
              detail="Private NIC; TCP 80")
    draw.edge("client", "lb", "TCP 80", label_pos=(315, 285))
    draw.edge("lb", "vm0", "80 → 80", points=[(750, 265)], label_pos=(760, 240))
    draw.edge("lb", "vm1", "80 → 80", points=[(750, 510)], label_pos=(750, 490))
    draw.line([(610, 365), (835, 365), (835, 300), (915, 300)],
              "TCP 80 probe", label_pos=(765, 340), style="dotted")
    draw.line([(835, 365), (835, 580), (915, 580)], style="dotted")
    draw.line([(915, 610), (700, 610), (700, 480), (610, 480)],
              "Outbound SNAT", label_pos=(735, 590))
    draw.edge("lb", "internet", "Outbound", points=[(310, 550)],
              label_pos=(315, 600))
    draw.note("Solid arrows = traffic and the explicit egress path; dotted arrows = TCP health probes. "
              "Both backends can use the outbound rule. A TCP probe does not validate the HTTP body.")


def inbound_nat_mapping(draw, item):
    """CLZ-230: the single RDP NAT rule targets only the first backend NIC."""
    draw.group("Private backend pool", 855, 155, 320, 475)
    draw.node("admin", "Administrator /32", "terminal", 35, 180, 235, 170,
              detail="Connect to public IP:50001")
    draw.node("webclient", "HTTP client", "cloud", 35, 450, 235, 170,
              detail="Connect to public IP:80")
    draw.node("lb", "Standard Load Balancer", "loadbalancer", 410, 310, 250, 190,
              detail="Shared public frontend")
    draw.node("first", "web[0]: NAT target", "windows", 895, 210, 240, 170,
              detail="IIS + scoped RDP")
    draw.node("second", "web[1]: HTTP pool", "windows", 895, 435, 240, 170,
              detail="No RDP NAT association")
    draw.edge("admin", "lb", "TCP 50001", label_pos=(325, 300))
    draw.edge("lb", "first", "TCP 3389", label_pos=(775, 300))
    draw.edge("webclient", "lb", "TCP 80", label_pos=(330, 525))
    draw.edge("lb", "second", "Pool traffic: TCP 80", label_pos=(775, 535))
    draw.text("50001 → 3389", 535, 215, size=36, color="#78d4ff", width=18,
              weight="700", anchor="middle")
    draw.text("One frontend port → one NIC", 535, 265, size=23, width=34,
              anchor="middle")
    draw.note("Solid arrows = the illustrated traffic paths. The RDP NAT association selects web[0] only; "
              "both VMs belong to the HTTP backend pool. The VM NSG still restricts RDP to admin_cidr.")


def count_indices(draw, item):
    """CLZ-240: the public IP, NIC, and VM share the same numeric index."""
    draw.text("instance_count = 2", 60, 185, size=28, color="#78d4ff", width=35,
              weight="700")
    for index, y in ((0, 250), (1, 475)):
        draw.group(f"Index [{index}] · generated name suffix count-{index + 1}",
                   40, y - 45, 1120, 195)
        draw.node(f"pip{index}", f"Public IP [{index}]", "cloud", 80, y, 230, 145,
                  detail="Standard; static")
        draw.node(f"nic{index}", f"NIC [{index}]", "network", 490, y, 230, 145,
                  detail="Web subnet; shared NSG")
        draw.node(f"vm{index}", f"Windows VM [{index}]", "windows", 900, y, 230, 145,
                  detail="Windows Server 2022")
        draw.edge(f"pip{index}", f"nic{index}", "Same index",
                  label_pos=(400, y + 55))
        draw.edge(f"nic{index}", f"vm{index}", "Same index",
                  label_pos=(810, y + 55))
    draw.note("Solid arrows = deployed resource references. Reducing count from 2 to 1 removes the [1] "
              "resource chain. Index-based identity is not a server role; no IIS extension is deployed here.")


def for_each_keys(draw, item):
    """CLZ-250: stable map keys connect each VM to its corresponding NIC/IP."""
    draw.group('Key "web"', 490, 155, 685, 235)
    draw.group('Key "ops"', 490, 405, 685, 225)
    draw.node("map", "vm_definitions map", "tf", 45, 305, 270, 190,
              detail='Keys: "web" and "ops"')
    draw.node("web", 'VM ["web"]', "windows", 540, 215, 235, 165,
              detail="Role tag: web")
    draw.node("ops", 'VM ["ops"]', "windows", 540, 455, 235, 165,
              detail="Role tag: operations")
    draw.node("webpip", 'Public IP ["web"]', "cloud", 915, 215, 235, 165,
              detail="NIC uses the same key")
    draw.node("opspip", 'Public IP ["ops"]', "cloud", 915, 455, 235, 165,
              detail="NIC uses the same key")
    draw.edge("map", "web", 'each.key = "web"', label_pos=(405, 280))
    draw.edge("map", "ops", 'each.key = "ops"', label_pos=(405, 520))
    draw.edge("webpip", "web", "Keyed NIC binding", label_pos=(845, 200))
    draw.edge("opspip", "ops", "Keyed NIC binding", label_pos=(845, 440))
    draw.text("Add a key without renumbering", 45, 220, size=25, width=30)
    draw.text("existing resource keys.", 45, 255, size=25, width=30)
    draw.note("Solid arrows = keyed configuration references, not packet routes. IP, NIC, and VM use "
              "the same each.key. Renaming a key changes identity; this lesson does not install IIS.")


def manual_capacity(draw, item):
    """CLZ-260: instance count changes and Manual model upgrades differ."""
    draw.node("count", "instance_count", "plan", 35, 245, 250, 185,
              detail="Default 2; integer 1–5")
    draw.node("vmss", "Uniform Windows VMSS", "server", 445, 245, 290, 185,
              detail="Replaceable instances")
    draw.node("lb", "Standard Load Balancer", "loadbalancer", 915, 175, 245, 175,
              detail="HTTP 80 + explicit egress")
    draw.node("extension", "IIS extension model", "terminal", 915, 450, 245, 175,
              detail="Manual upgrade policy")
    draw.node("inspect", "Check actual instances", "search", 445, 475, 290, 150,
              detail="Capacity; model; HTTP")
    draw.edge("count", "vmss", "Review + apply count", label_pos=(365, 230))
    draw.edge("lb", "vmss", "Healthy TCP 80", label_pos=(820, 275))
    draw.edge("extension", "vmss", "Configure IIS model", label_pos=(805, 455))
    draw.edge("inspect", "vmss", "Inspect", style="dotted", label_pos=(645, 458))
    draw.text("Capacity change ≠ model rollout", 45, 195, size=28, width=50,
              color="#78d4ff", weight="700")
    draw.note("Solid arrows = module/configuration relationships; dotted arrow = inspection. "
              "With Manual upgrades, review and update existing instances to the latest model when required.")


def cpu_autoscaling(draw, item):
    """CLZ-270: platform CPU feeds bounded, delayed ChangeCount actions."""
    draw.node("metric", "VMSS CPU metric", "monitor", 40, 300, 240, 185,
              detail="Percentage CPU; average")
    draw.node("policy", "Autoscale setting", "plan", 435, 300, 300, 185,
              detail="Above 70%: +1; below 25%: −1")
    draw.node("vmss", "Windows IIS VMSS", "server", 900, 300, 260, 185,
              detail="Shared load-balanced tier")
    draw.edge("metric", "policy", "Evaluate", label_pos=(355, 355))
    draw.edge("policy", "vmss", "±1 instance", label_pos=(815, 355))
    draw.line([(1030, 300), (1030, 180), (160, 180), (160, 300)],
              "Platform CPU metric", label_pos=(595, 205), style="dotted")
    draw.group("Configured capacity bounds", 340, 520, 530, 110)
    draw.icon("shield", 365, 560, size=55, color="#9fafff")
    draw.text("Minimum 2 · default 2 · maximum 4", 455, 572, size=23, width=34)
    draw.text("5-minute metric window + 5-minute cooldown", 600, 260, size=25,
              width=72, anchor="middle")
    draw.note("Solid arrows = the autoscale control path; dotted arrow = observed platform metrics. "
              "Capacity bounds limit instance count, not currency spend. Review later Terraform plans for capacity drift.")


SCENES = {
    "CLZ-190": vm_components,
    "CLZ-200": iis_bootstrap,
    "CLZ-210": bastion_connection,
    "CLZ-220": load_balancer_paths,
    "CLZ-230": inbound_nat_mapping,
    "CLZ-240": count_indices,
    "CLZ-250": for_each_keys,
    "CLZ-260": manual_capacity,
    "CLZ-270": cpu_autoscaling,
}

DESCRIPTIONS = {
    "CLZ-190": "A Windows VM's public IP, scoped NIC NSG, private NIC, OS disk, and generated password dependencies; no IIS is deployed.",
    "CLZ-200": "Terraform configures a Custom Script Extension; PowerShell installs IIS and writes index.html, then a separate HTTP check verifies status and page content.",
    "CLZ-210": "The administrator browser connects to Azure Bastion over HTTPS 443; Bastion connects to the private Windows VM over TCP 3389 allowed by its NSG.",
    "CLZ-220": "Standard Load Balancer routes TCP 80 to two private IIS backends, checks separate TCP probes, and supplies explicit outbound SNAT.",
    "CLZ-230": "The public frontend maps TCP 50001 to TCP 3389 on web[0] only; both private IIS VMs remain in the HTTP backend pool.",
    "CLZ-240": "Two count-indexed chains bind public IP [0] to NIC [0] to VM [0], and public IP [1] to NIC [1] to VM [1]; no IIS extension is deployed.",
    "CLZ-250": "The web and ops map keys identify matching Windows VM, NIC, and public IP instances without numeric renumbering; no IIS extension is deployed.",
    "CLZ-260": "A validated instance_count controls VMSS capacity through the shared IIS module; instance inspection distinguishes capacity changes from Manual model upgrades.",
    "CLZ-270": "Average platform CPU drives +1 above 70 percent and minus 1 below 25 percent, with five-minute windows and cooldowns and default capacity bounds of 2, 2, and 4.",
}

# The shared validator resolves module sources before checking resource tokens.
EXPECTED_RESOURCES = {
    "CLZ-190": ("azurerm_public_ip.web", "azurerm_network_interface.web", "azurerm_network_security_group.web", "azurerm_windows_virtual_machine.web", "random_password.windows_admin"),
    "CLZ-200": ("azurerm_windows_virtual_machine.web", "azurerm_virtual_machine_extension.iis", "azurerm_public_ip.web"),
    "CLZ-210": ("azurerm_subnet.bastion", "azurerm_public_ip.bastion", "azurerm_bastion_host.main", "azurerm_network_interface.private_web", "azurerm_windows_virtual_machine.private_web"),
    "CLZ-220": ("azurerm_lb.web", "azurerm_lb_probe.http", "azurerm_lb_rule.http", "azurerm_lb_outbound_rule.web", "azurerm_windows_virtual_machine.web"),
    "CLZ-230": ("azurerm_lb_nat_rule.rdp_first", "azurerm_network_interface_nat_rule_association.rdp_first", "azurerm_lb_backend_address_pool.web", "azurerm_windows_virtual_machine.web"),
    "CLZ-240": ("azurerm_public_ip.web", "azurerm_network_interface.web", "azurerm_windows_virtual_machine.web"),
    "CLZ-250": ("azurerm_public_ip.web", "azurerm_network_interface.web", "azurerm_windows_virtual_machine.web"),
    "CLZ-260": ("azurerm_windows_virtual_machine_scale_set.web", "azurerm_virtual_machine_scale_set_extension.iis", "azurerm_lb.web", "azurerm_lb_outbound_rule.web"),
    "CLZ-270": ("azurerm_monitor_autoscale_setting.web", "azurerm_windows_virtual_machine_scale_set.web", "azurerm_virtual_machine_scale_set_extension.iis"),
}

EXPECTED_CONNECTIONS = {
    "CLZ-190": ("public_ip_address_id          = azurerm_public_ip.web.id", "network_security_group_id = azurerm_network_security_group.web.id", 'storage_account_type = "Standard_LRS"'),
    "CLZ-200": ("virtual_machine_id         = azurerm_windows_virtual_machine.web.id", "Install-WindowsFeature -Name Web-Server -IncludeManagementTools", "index.html"),
    "CLZ-210": ("source_address_prefix       = azurerm_subnet.bastion.address_prefixes[0]", 'name                 = "AzureBastionSubnet"', 'address_prefixes     = ["10.40.20.0/26"]'),
    "CLZ-220": ("probe_id                       = azurerm_lb_probe.http.id", "disable_outbound_snat          = true", "backend_address_pool_id = azurerm_lb_backend_address_pool.web.id", "count               = 2"),
    "CLZ-230": ("frontend_port                  = 50001", "backend_port                   = 3389", "network_interface_id  = azurerm_network_interface.web[0].id"),
    "CLZ-240": ("count               = var.instance_count", "public_ip_address_id          = azurerm_public_ip.web[count.index].id", "azurerm_network_interface.web[count.index].id"),
    "CLZ-250": ("for_each            = var.vm_definitions", "public_ip_address_id          = azurerm_public_ip.web[each.key].id", "azurerm_network_interface.web[each.key].id", "size                = each.value.vm_size"),
    "CLZ-260": ("instance_count      = var.instance_count", 'upgrade_mode         = "Manual"', "instances            = var.instance_count"),
    "CLZ-270": ("instance_count      = var.autoscale_capacity.default", "target_resource_id  = module.windows_iis_vmss.vmss_id", "threshold          = 70", "threshold          = 25", 'cooldown  = "PT5M"'),
}
