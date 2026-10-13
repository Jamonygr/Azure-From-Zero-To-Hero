"""Lesson-specific platform and operations illustrations.

The callable scenes deliberately distinguish declared infrastructure from
existing prerequisites and examples. Dashed lines never claim a deployment.
Only the shared Drawing API is used, keeping rendering deterministic.
"""

from __future__ import annotations


def nat_outbound(d, item):
    d.group("VNet: only web-snet is associated", 40, 190, 350, 410)
    d.node("future", "Future workload", "server", 75, 260, 280, 165,
           detail="Example only: no VM deployed")
    d.node("nat", "NAT Gateway", "network", 450, 260, 210, 165,
           detail="Subnet outbound SNAT")
    d.node("ip", "Standard public IP", "cloud", 725, 260, 210, 165,
           detail="Static egress address")
    d.node("internet", "Internet", "cloud", 1000, 275, 155, 145)
    d.edge("future", "nat", "future", style="dashed",
           label_pos=(407, 325))
    d.edge("nat", "ip", "bind", label_pos=(694, 325))
    d.edge("ip", "internet", "egress", style="dashed",
           label_pos=(1035, 240))
    d.text("app / data / mgmt", 75, 490, size=22, width=23)
    d.text("No NAT association", 75, 535, size=20, width=25)
    d.icon("search", 490, 485, size=66)
    d.text("Validate the subnet link and public IP.", 580, 505,
           size=23, width=43)
    d.note("NAT is outbound connectivity, not inbound access or a filtering firewall. "
           "This lesson creates no workload for an egress test.")


def private_dns(d, item):
    d.group("Linked network", 40, 200, 310, 380)
    d.node("vnet", "VNet", "network", 70, 270, 250, 165,
           detail="Private zone resolution")
    d.node("zone", "Private DNS zone", "dns", 440, 245, 270, 190,
           detail="clz.internal")
    d.node("record", "web A record", "dns", 825, 245, 285, 190,
           detail="web.clz.internal → 10.40.1.10")
    d.edge("vnet", "zone", "link", label_pos=(395, 335))
    d.edge("zone", "record", "manual", label_pos=(770, 325))
    d.node("host", "No host is created", "server", 825, 485, 285, 140,
           detail="A DNS record is not a VM")
    d.edge("record", "host", "example address", style="dashed",
           label_pos=(975, 460))
    d.icon("search", 450, 490, size=65)
    d.text("Registration disabled", 540, 510, size=23, width=20)
    d.note("The record's address is illustrative. A lookup may resolve while no service "
           "exists at that IP; linked-network clients must test the actual workload.")


def optional_public_dns(d, item):
    d.node("plan", "Review the plan", "plan", 60, 325, 245, 165,
           detail="Zone creation defaults false")
    d.group("Terraform-managed resources", 400, 170, 350, 450)
    d.node("rg", "Lesson resource group", "folder", 430, 230, 290, 140,
           detail="Created on the default path")
    d.node("zone", "Owned public zone", "dns", 430, 430, 290, 155,
           detail="Only with explicit opt-in")
    d.edge("plan", "rg", "default", points=[(345, 400), (345, 300)],
           label_pos=(350, 270))
    d.edge("plan", "zone", "optional", style="dashed",
           label_pos=(350, 495))
    d.node("registrar", "Your registrar", "user", 850, 430, 285, 155,
           detail="External ownership / delegation")
    d.node("public", "Public DNS authority", "cloud", 850, 215, 285, 155,
           detail="Controlled by delegation")
    d.edge("zone", "registrar", "NS records", style="dotted",
           label_pos=(793, 490))
    d.edge("registrar", "public", "delegate separately", style="dashed",
           label_pos=(995, 395))
    d.note("Azure does not buy the domain or update your registrar. Keep creation disabled "
           "without an owned domain; Terraform check warnings do not block apply.")


def remote_state_migration(d, item):
    d.node("local", "CLZ-310 local state", "folder", 55, 230, 285, 180,
           detail="Bootstrap first; backend=false")
    d.node("blob", "Protected Azure backend", "storage", 465, 230, 305, 180,
           detail="Private tfstate container")
    d.node("consumer", "CLZ-320 consumer", "plan", 890, 230, 255, 180,
           detail="Separate dependent lesson")
    d.edge("local", "blob", "migrate", label_pos=(402, 305))
    d.edge("blob", "consumer", "outputs", style="dashed",
           label_pos=(830, 305))
    d.icon("lock", 475, 470, size=74)
    d.text("Blob key: clz310.tfstate", 575, 472, size=24, width=40)
    d.text("Entra ID data access + current /32 + blob lease", 575, 520,
           size=21, width=45)
    d.icon("trash", 70, 485, size=65)
    d.text("Backend stays alive until the consumer is gone.", 155, 503,
           size=22, width=23)
    d.note("Cleanup order: 1 destroy CLZ-320 · 2 migrate CLZ-310 back to local state · "
           "3 destroy the backend. Keep protected state recovery copies until migration is verified.")


def remote_state_contract(d, item):
    d.node("producer", "Existing CLZ-310 blob", "storage", 50, 225, 295, 190,
           detail="Producer-owned prerequisite")
    d.node("coordinates", "Typed backend coordinates", "plan", 440, 225, 300, 190,
           detail="Account · container · key · group")
    d.node("reader", "CLZ-320 state reader", "search", 845, 225, 295, 190,
           detail="Entra ID; exported root outputs")
    d.edge("producer", "coordinates", "metadata", style="dotted",
           label_pos=(390, 305))
    d.edge("coordinates", "reader", "contract", style="dotted",
           label_pos=(790, 305))
    d.node("own", "Consumer resource group", "folder", 845, 465, 295, 170,
           detail="CLZ-320 owns its local state")
    d.edge("reader", "own", "own lifecycle", label_pos=(995, 448))
    d.icon("shield", 65, 470, size=72)
    d.text("Backend coordinates are not the state snapshot.", 165, 477,
           size=23, width=43)
    d.text("Remote-state access can expose the whole producer snapshot.", 165, 535,
           size=21, width=48)
    d.note("The consumer reads CLZ-310 output metadata; it does not own or migrate the "
           "producer backend. Destroy CLZ-320 before CLZ-310's migration-back cleanup.")


def traffic_manager_dns(d, item):
    d.node("client", "Client browser", "user", 50, 325, 235, 180,
           detail="Uses its requested hostname")
    d.node("tm", "Traffic Manager", "dns", 415, 195, 300, 180,
           detail="Priority DNS · TTL 60")
    d.node("primary", "Primary endpoint", "server", 865, 185, 275, 170,
           detail="Existing HTTPS service · priority 1")
    d.node("secondary", "Secondary endpoint", "server", 865, 435, 275, 170,
           detail="Existing HTTPS service · priority 2")
    d.edge("tm", "client", "DNS answer", style="dotted",
           label_pos=(330, 300))
    d.edge("tm", "primary", "HTTPS probe", style="dotted",
           label_pos=(790, 250))
    d.edge("tm", "secondary", "HTTPS probe", style="dotted",
           points=[(770, 285), (770, 520)], label_pos=(790, 430))
    d.edge("client", "primary", "HTTPS directly",
           points=[(365, 570), (815, 570), (815, 300)],
           label_pos=(555, 545))
    d.note("Traffic Manager never proxies the client connection or terminates TLS. "
           "Online probes do not prove the requested hostname's certificate or host routing; "
           "the lesson owns registrations, not the endpoint services.")


def vault_secret_and_state(d, item):
    d.node("password", "Generated password", "key", 50, 205, 295, 185,
           detail="Terraform random_password")
    d.node("vault", "Key Vault secret", "vault", 455, 205, 300, 185,
           detail="windows-admin-password")
    d.node("state", "Terraform state", "folder", 880, 205, 275, 185,
           detail="Contains the generated value")
    d.edge("password", "vault", "store", label_pos=(399, 285))
    d.edge("password", "state", "record in state",
           points=[(195, 160), (1015, 160)], label_pos=(605, 170))
    d.node("identity", "Applying identity", "user", 50, 460, 295, 145,
           detail="Access policy + public IPv4 /32")
    d.node("metadata", "Inspect metadata", "search", 455, 460, 300, 145,
           detail="Secret ID and enabled state")
    d.edge("identity", "vault", "authorized access", points=[(385, 535), (385, 300)],
           label_pos=(391, 433))
    d.edge("vault", "metadata", "no value output", style="dotted",
           label_pos=(608, 425))
    d.icon("shield", 950, 435, size=74)
    d.text("Protect state and plan files.", 890, 555, size=22, width=21)
    d.note("Sensitive output redaction does not remove secrets from state. This lab uses "
           "access policies, not Azure RBAC; production needs role separation and purge protection.")


def blob_private_endpoint(d, item):
    d.group("Linked VNet: private data path", 45, 365, 750, 245)
    d.node("client", "Existing private client", "server", 75, 415, 245, 165,
           detail="Prerequisite; not deployed here")
    d.node("dns", "Blob Private DNS", "dns", 480, 180, 305, 170,
           detail="Blob Private Link zone")
    d.node("pe", "Blob Private Endpoint", "network", 500, 415, 255, 165,
           detail="data-snet · private 10.40.3.x")
    d.node("account", "Storage account", "storage", 890, 385, 265, 200,
           detail="Public network access disabled")
    d.edge("client", "dns", "normal blob FQDN", style="dotted",
           points=[(195, 280), (435, 280)], label_pos=(303, 257))
    d.edge("dns", "pe", "private A record", style="dotted",
           label_pos=(630, 386))
    d.edge("client", "pe", "HTTPS 443", style="dashed",
           label_pos=(407, 477))
    d.edge("pe", "account", "blob", label_pos=(820, 480))
    d.note("Use the normal blob hostname from a connected client. Approved is control-plane "
           "evidence; data access still requires private routing, correct DNS, TLS, and authorization.")


def monitor_foundation(d, item):
    d.group("Provisioned foundation", 40, 180, 580, 440)
    d.node("workspace", "Log Analytics workspace", "monitor", 80, 235, 285, 175,
           detail="30-day retention · no source")
    d.node("actions", "Enabled action group", "monitor", 295, 435, 285, 150,
           detail="No receivers configured")
    d.group("Not configured by this lesson", 700, 180, 460, 440)
    d.node("source", "Agent / collection rule", "server", 755, 235, 345, 175,
           detail="Illustrated future addition")
    d.node("alert", "Alert rule + receivers", "monitor", 755, 435, 345, 150,
           detail="Illustrated future addition")
    d.edge("source", "workspace", "collect data", style="dashed",
           label_pos=(556, 310))
    d.edge("alert", "actions", "wire alerts", style="dashed",
           label_pos=(663, 505))
    d.note("An empty workspace is expected. The action group is not an alert rule and "
           "does not send notifications without a configured signal, rule, and receiver.")


def ci_validation_and_oidc(d, item):
    d.group("Credential-free PR checks", 40, 175, 520, 430)
    d.node("pr", "Pull request", "git", 70, 235, 210, 160,
           detail="Only if example is enabled")
    d.node("validate", "Source validation", "tf", 340, 235, 185, 170,
           detail="init · fmt · validate")
    d.edge("pr", "validate", "checks", style="dashed", label_pos=(310, 420))
    d.text("Backend-free initialization", 75, 475, size=24, width=32)
    d.text("No Azure credential or apply", 75, 530, size=22, width=35)
    d.group("Separate manual plan example", 600, 175, 555, 430)
    d.node("gate", "Environment + OIDC", "shield", 635, 235, 235, 175,
           detail="Owner-defined trust / approval")
    d.node("plan", "Terraform plan", "plan", 945, 235, 175, 160,
           detail="No apply step")
    d.edge("gate", "plan", "login", style="dashed", label_pos=(908, 305))
    d.node("proposal", "Tagged resource-group proposal", "folder", 635, 470, 485, 135,
           detail="Planned; never created by this workflow")
    d.edge("plan", "proposal", "proposal only", style="dashed",
           label_pos=(1015, 437))
    d.note("The .yml.example files are inactive teaching materials until deliberately "
           "copied and enabled. Cloud plans remain separate from credential-free checks and deploy no resources.")


def sql_private_access(d, item):
    d.group("Linked VNet: representative client path", 40, 375, 735, 240)
    d.node("client", "Existing SQL client", "server", 70, 425, 235, 165,
           detail="Prerequisite; not created here")
    d.node("dns", "SQL Private DNS", "dns", 470, 180, 295, 170,
           detail="SQL Private Link zone")
    d.node("pe", "SQL Private Endpoint", "network", 440, 425, 295, 165,
           detail="sqlServer · data-snet")
    d.group("Managed SQL service", 830, 180, 340, 435)
    d.node("server", "SQL logical server", "sql", 860, 240, 280, 160,
           detail="Public network disabled · TLS 1.2")
    d.node("db", "clzdb database", "sql", 860, 480, 280, 125,
           detail="Basic SKU")
    d.edge("client", "dns", "normal SQL FQDN", style="dotted",
           points=[(190, 280), (430, 280)], label_pos=(302, 257))
    d.edge("dns", "pe", "private A record", style="dotted",
           label_pos=(613, 389))
    d.edge("client", "pe", "TCP 1433", style="dashed",
           label_pos=(373, 490))
    d.edge("pe", "server", "sqlServer",
           points=[(792, 510), (792, 320)], label_pos=(807, 431))
    d.edge("server", "db", "owns database", label_pos=(1007, 444))
    d.note("Use the normal database hostname from a private client. DNS and TCP checks "
           "do not prove a SQL login or query; the generated admin password remains in Terraform state.")


def capstone_paths(d, item):
    d.node("web", "Web client", "user", 40, 210, 210, 150,
           detail="Demonstration HTTP")
    d.node("lb", "Standard LB", "loadbalancer", 325, 210, 255, 150,
           detail="TCP 80 probe + outbound rule")
    d.group("Workload subnet: web-snet", 300, 405, 645, 205)
    d.node("nsg", "Web subnet NSG", "shield", 330, 445, 245, 145,
           detail="HTTP + Bastion-only RDP")
    d.node("vmss", "Windows IIS VMSS", "windows", 690, 440, 225, 170,
           detail="Private NICs · IIS extension")
    d.node("bastion", "Azure Bastion", "bastion", 40, 445, 220, 145,
           detail="Dedicated /26 subnet")
    d.node("password", "Generated admin password", "key", 680, 175, 235, 160,
           detail="Also recorded in state")
    d.node("vault", "Key Vault", "vault", 980, 175, 180, 160,
           detail="Secret + applying identity /32")
    d.node("logs", "Log Analytics", "monitor", 980, 440, 180, 150,
           detail="Workspace only")
    d.edge("web", "lb", "HTTP 80", label_pos=(290, 385))
    d.edge("lb", "nsg", "HTTP allow", label_pos=(455, 389))
    d.edge("bastion", "nsg", "RDP", label_pos=(295, 510))
    d.edge("nsg", "vmss", "80 / 3389", label_pos=(630, 510))
    d.edge("password", "vmss", "admin input", label_pos=(798, 387))
    d.edge("password", "vault", "store", label_pos=(948, 245))
    d.edge("vmss", "lb", "outbound rule",
           points=[(800, 628), (618, 628), (618, 285)],
           label_pos=(700, 637))
    d.note("This capstone has no autoscale rule, managed TLS, guest Key Vault retrieval, "
           "or telemetry collection wiring. Verify HTTP, NSG, Bastion, vault, and explicit outbound behavior.")


SCENES = {
    "CLZ-280": nat_outbound,
    "CLZ-290": private_dns,
    "CLZ-300": optional_public_dns,
    "CLZ-310": remote_state_migration,
    "CLZ-320": remote_state_contract,
    "CLZ-330": traffic_manager_dns,
    "CLZ-340": vault_secret_and_state,
    "CLZ-350": blob_private_endpoint,
    "CLZ-360": monitor_foundation,
    "CLZ-370": ci_validation_and_oidc,
    "CLZ-380": sql_private_access,
    "CLZ-390": capstone_paths,
}

DESCRIPTIONS = {
    "CLZ-280": "NAT Gateway and a Standard static public IP are associated only with web-snet. "
               "A dashed future-workload egress path is illustrative: this lesson deploys no VM "
               "and NAT provides neither inbound access nor firewall filtering.",
    "CLZ-290": "A VNet link connects private clz.internal resolution to a manually configured "
               "web A record for 10.40.1.10. Registration is disabled and the address does not "
               "represent a host deployed by this lesson.",
    "CLZ-300": "The default path creates a resource group without a public DNS zone. A dashed "
               "opt-in branch creates an owned zone, while registrar delegation remains external. "
               "Public authority depends on delegation and check warnings do not block apply.",
    "CLZ-310": "Bootstrap CLZ-310 with local state, migrate it to the protected tfstate blob, "
               "and keep the backend for the separate CLZ-320 consumer. Cleanup first removes "
               "the consumer, migrates CLZ-310 back locally, then destroys the backend.",
    "CLZ-320": "CLZ-320 reads exported root outputs from an existing CLZ-310 blob using four typed "
               "backend coordinates and Microsoft Entra ID. Its own resource group and local state have "
               "a separate lifecycle; state-reading permissions can expose the producer snapshot.",
    "CLZ-330": "Traffic Manager returns priority-based DNS answers and probes two existing HTTPS "
               "services. The client's HTTPS connection goes directly to an endpoint. Traffic "
               "Manager does not terminate TLS; the client hostname still needs endpoint certificate "
               "coverage and correct host routing.",
    "CLZ-340": "Terraform generates a password, stores it in a Key Vault secret, and retains its "
               "value in state. The applying identity uses an access policy and restricted IPv4 "
               "path. Validation reads metadata, while sensitive redaction does not remove state secrets.",
    "CLZ-350": "A blob Private Endpoint in data-snet connects the public-disabled Storage account "
               "to its private DNS overlay. A dashed existing-client path resolves the normal blob "
               "hostname privately and still needs correct routing, TLS, and data authorization.",
    "CLZ-360": "The lesson provisions a 30-day Log Analytics workspace and an enabled action group "
               "with no receivers. Dashed collection and alert connections are future additions; "
               "no agent, data collection rule, alert rule, or notification receiver is configured.",
    "CLZ-370": "Two inactive workflow examples separate credential-free PR source checks from an "
               "owner-configured manual OIDC plan behind an environment gate. The resource group "
               "is a proposal only; neither example includes an apply operation.",
    "CLZ-380": "The SQL logical server and Basic database have public network access disabled. "
               "A sqlServer Private Endpoint and linked SQL Private DNS support the normal hostname "
               "for an existing private client. DNS or TCP success does not prove SQL authentication.",
    "CLZ-390": "Public HTTP passes through the Standard Load Balancer and web NSG to private IIS "
               "VMSS instances; Bastion supplies the separately admitted RDP path. A generated "
               "password feeds VMSS and Key Vault and remains in state. Outbound SNAT is explicit. "
               "Log Analytics is a workspace without telemetry wiring; autoscale and managed TLS "
               "are production additions.",
}

EXPECTED_RESOURCES = {
    "CLZ-280": ("azurerm_nat_gateway.main", "azurerm_public_ip.nat",
                "azurerm_subnet_nat_gateway_association.web",
                "azurerm_nat_gateway_public_ip_association.main", "azurerm_subnet.web"),
    "CLZ-290": ("azurerm_private_dns_zone.internal",
                "azurerm_private_dns_zone_virtual_network_link.internal",
                "azurerm_private_dns_a_record.web", "azurerm_virtual_network.main"),
    "CLZ-300": ("azurerm_resource_group.lab", "azurerm_dns_zone.public"),
    "CLZ-310": ("azurerm_storage_account.state", "azurerm_storage_container.state",
                "azurerm_storage_account_queue_properties.state"),
    "CLZ-320": ("data.terraform_remote_state.shared", "azurerm_resource_group.lab"),
    "CLZ-330": ("azurerm_traffic_manager_profile.web",
                "azurerm_traffic_manager_external_endpoint.primary",
                "azurerm_traffic_manager_external_endpoint.secondary"),
    "CLZ-340": ("random_password.windows_admin", "azurerm_key_vault.lab",
                "azurerm_key_vault_secret.windows_admin_password", "data.azurerm_client_config.current"),
    "CLZ-350": ("azurerm_storage_account.private", "azurerm_private_endpoint.blob",
                "azurerm_private_dns_zone.blob",
                "azurerm_private_dns_zone_virtual_network_link.blob", "azurerm_subnet.data"),
    "CLZ-360": ("azurerm_log_analytics_workspace.main", "azurerm_monitor_action_group.ops"),
    "CLZ-370": ("azurerm_resource_group.lab",),
    "CLZ-380": ("azurerm_mssql_server.main", "azurerm_mssql_database.main",
                "azurerm_private_endpoint.sql", "azurerm_private_dns_zone.sql",
                "azurerm_private_dns_zone_virtual_network_link.sql", "azurerm_subnet.data"),
    "CLZ-390": ("module.network", "module.windows_iis_vmss", "azurerm_network_security_group.web",
                "azurerm_subnet_network_security_group_association.web",
                "azurerm_bastion_host.main", "azurerm_subnet.bastion", "azurerm_public_ip.bastion",
                "azurerm_key_vault.lab", "azurerm_key_vault_secret.windows_admin_password",
                "random_password.windows_admin", "azurerm_log_analytics_workspace.main"),
}

EXPECTED_CONNECTIONS = {
    "CLZ-280": ("subnet_id = azurerm_subnet.web.id",
                "nat_gateway_id = azurerm_nat_gateway.main.id",
                "public_ip_address_id = azurerm_public_ip.nat.id"),
    "CLZ-290": ('name = "clz.internal"', "registration_enabled = false",
                'records = ["10.40.1.10"]', "virtual_network_id = azurerm_virtual_network.main.id"),
    "CLZ-300": ("count = var.create_public_dns_zone ? 1 : 0", "name = var.dns_zone_name"),
    "CLZ-310": ('container_access_type = "private"', 'default_action = "Deny"',
                'ip_rules = [split("/", var.backend_access_cidr)[0]]'),
    "CLZ-320": ('backend = "azurerm"', "use_azuread_auth = true",
                "key = var.remote_state.key", "shared_outputs = try(data.terraform_remote_state.shared.outputs, {})"),
    "CLZ-330": ('traffic_routing_method = "Priority"', "ttl = 60", 'protocol = "HTTPS"',
                "target = var.primary_endpoint_fqdn", "target = var.secondary_endpoint_fqdn"),
    "CLZ-340": ("value = random_password.windows_admin.result",
                "object_id = data.azurerm_client_config.current.object_id",
                "purge_protection_enabled = false"),
    "CLZ-350": ("public_network_access_enabled = false", 'subresource_names = ["blob"]',
                "subnet_id = azurerm_subnet.data.id", 'name = "privatelink.blob.core.windows.net"'),
    "CLZ-360": ("retention_in_days = 30", 'short_name = "clzops"'),
    "CLZ-370": ('resource "azurerm_resource_group" "lab"',),
    "CLZ-380": ("public_network_access_enabled = false", 'subresource_names = ["sqlServer"]',
                'name = "privatelink.database.windows.net"', 'sku_name = "Basic"'),
    "CLZ-390": ("subnet_id = module.network.web_subnet_id",
                "admin_password = random_password.windows_admin.result",
                'source_address_prefix = "10.40.20.0/26"',
                'destination_port_range = "3389"', "disable_outbound_snat = true",
                'resource "azurerm_lb_outbound_rule" "web"', 'protocol = "Tcp"'),
}
