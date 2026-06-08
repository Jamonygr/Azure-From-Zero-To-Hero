param()

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Write-LabFile {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Content
  )

  $target = Join-Path $Root $RelativePath
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }

  $normalized = $Content.TrimStart("`r", "`n").TrimEnd() + "`r`n"
  Set-Content -LiteralPath $target -Value $normalized -Encoding utf8
}

function Expand-Template {
  param(
    [Parameter(Mandatory = $true)][string]$Template,
    [Parameter(Mandatory = $true)][hashtable]$Values
  )

  $result = $Template
  foreach ($key in $Values.Keys) {
    $result = $result.Replace("{{$key}}", [string]$Values[$key])
  }
  return $result
}

$Lessons = @(
  [ordered]@{ Number = 1; Id = "CLZ-100"; Folder = "CLZ-100-foundations"; Title = "Foundations"; Topic = "IaC, Terraform, and Azure lab model"; Build = "A tagged resource group and the mental model for every later lab."; Outcomes = "Explain desired state; map Terraform files to Azure resources; read a plan before applying it."; Diagram = "terraform-workflow.svg"; Next = "Prepare the Windows workstation toolchain." },
  [ordered]@{ Number = 2; Id = "CLZ-110"; Folder = "CLZ-110-windows-workstation-setup"; Title = "Windows Workstation Setup"; Topic = "Terraform, Azure CLI, VS Code, Git, and PowerShell"; Build = "A verified local toolchain for running the whole curriculum."; Outcomes = "Confirm tool versions; sign in to Azure CLI; select the intended subscription."; Diagram = "terraform-workflow.svg"; Next = "Run the Terraform workflow end to end." },
  [ordered]@{ Number = 3; Id = "CLZ-120"; Folder = "CLZ-120-terraform-core-workflow"; Title = "Terraform Core Workflow"; Topic = "init, fmt, validate, plan, apply, and destroy"; Build = "A safe command routine that repeats in every lesson."; Outcomes = "Initialize providers; validate HCL; produce a saved plan; clean up with destroy."; Diagram = "terraform-workflow.svg"; Next = "Configure provider authentication clearly." },
  [ordered]@{ Number = 4; Id = "CLZ-130"; Folder = "CLZ-130-provider-authentication"; Title = "Provider Authentication"; Topic = "Azure provider and CLI authentication"; Build = "A provider configuration that can target one explicit subscription."; Outcomes = "Understand AzureRM provider setup; use subscription_id when needed; avoid accidental deployments."; Diagram = "terraform-workflow.svg"; Next = "Standardize names and tags." },
  [ordered]@{ Number = 5; Id = "CLZ-140"; Folder = "CLZ-140-resource-groups-tags"; Title = "Resource Groups And Tags"; Topic = "Resource groups, standard tags, and naming"; Build = "A naming and tagging pattern for the Chriz Labz estate."; Outcomes = "Use clz prefixes; tag resources consistently; make cleanup and cost review easier."; Diagram = "resource-naming.svg"; Next = "Make the configuration reusable with inputs and outputs." },
  [ordered]@{ Number = 6; Id = "CLZ-150"; Folder = "CLZ-150-variables-locals-outputs"; Title = "Variables Locals Outputs"; Topic = "Variables, locals, outputs, and tfvars examples"; Build = "A configurable lesson folder with safe example values."; Outcomes = "Change behavior with variables; keep derived names in locals; expose useful outputs."; Diagram = "resource-naming.svg"; Next = "Learn what Terraform records in state." },
  [ordered]@{ Number = 7; Id = "CLZ-160"; Folder = "CLZ-160-state-and-locking-basics"; Title = "State And Locking Basics"; Topic = "Local state safety and cleanup discipline"; Build = "A local-state workflow with clear safety rules."; Outcomes = "Identify state files; avoid committing runtime data; destroy resources from the owning folder."; Diagram = "remote-state.svg"; Next = "Start the Azure network foundation." },
  [ordered]@{ Number = 8; Id = "CLZ-170"; Folder = "CLZ-170-virtual-network-foundation"; Title = "Virtual Network Foundation"; Topic = "VNet, subnets, and address plan"; Build = "A four-subnet Azure network for web, app, data, and management workloads."; Outcomes = "Design address ranges; create subnets; prepare repeatable network outputs."; Diagram = "network-foundation.svg"; Next = "Attach security rules to the network." },
  [ordered]@{ Number = 9; Id = "CLZ-180"; Folder = "CLZ-180-network-security-groups"; Title = "Network Security Groups"; Topic = "NSGs and rule design"; Build = "A web subnet protected by HTTP and scoped RDP rules."; Outcomes = "Set rule priority; limit admin access; associate an NSG with a subnet."; Diagram = "network-foundation.svg"; Next = "Deploy the first Windows VM." },
  [ordered]@{ Number = 10; Id = "CLZ-190"; Folder = "CLZ-190-windows-vm-basics"; Title = "Windows VM Basics"; Topic = "First Windows VM"; Build = "A Windows Server VM with generated administrator credentials."; Outcomes = "Create NIC, public IP, VM, and sensitive output values; verify VM identity."; Diagram = "windows-iis-vm.svg"; Next = "Install IIS with PowerShell automation." },
  [ordered]@{ Number = 11; Id = "CLZ-200"; Folder = "CLZ-200-windows-vm-iis-bootstrap"; Title = "Windows VM IIS Bootstrap"; Topic = "IIS with PowerShell Custom Script Extension"; Build = "A Windows Server web node with IIS and a custom validation page."; Outcomes = "Use Custom Script Extension; publish a simple page; validate through HTTP."; Diagram = "windows-iis-vm.svg"; Next = "Move administration behind Azure Bastion." },
  [ordered]@{ Number = 12; Id = "CLZ-210"; Folder = "CLZ-210-azure-bastion-rdp"; Title = "Azure Bastion RDP"; Topic = "Bastion subnet, Bastion host, and private RDP"; Build = "A private Windows VM reachable through Azure Bastion."; Outcomes = "Create AzureBastionSubnet; remove public VM access; use browser-based RDP."; Diagram = "bastion-rdp.svg"; Next = "Put multiple Windows web nodes behind a load balancer." },
  [ordered]@{ Number = 13; Id = "CLZ-220"; Folder = "CLZ-220-standard-load-balancer-windows"; Title = "Standard Load Balancer Windows"; Topic = "Public Standard Load Balancer with Windows backend"; Build = "A public load balancer with two IIS Windows backends."; Outcomes = "Create frontend IP, backend pool, probe, rule, and NIC associations."; Diagram = "load-balancer-vmss.svg"; Next = "Add a controlled admin NAT pattern." },
  [ordered]@{ Number = 14; Id = "CLZ-230"; Folder = "CLZ-230-load-balancer-nat-rules"; Title = "Load Balancer NAT Rules"; Topic = "Controlled RDP NAT rule pattern"; Build = "A load balancer with HTTP delivery and one scoped RDP NAT rule."; Outcomes = "Understand frontend ports; associate a NAT rule; compare public and private access options."; Diagram = "load-balancer-vmss.svg"; Next = "Scale Windows VMs with count." },
  [ordered]@{ Number = 15; Id = "CLZ-240"; Folder = "CLZ-240-count-windows-vms"; Title = "Count Windows VMs"; Topic = "Terraform count with Windows VMs"; Build = "A small set of identical Windows VMs created from a count value."; Outcomes = "Use count.index; produce list outputs; understand when count is appropriate."; Diagram = "windows-iis-vm.svg"; Next = "Create named VMs with for_each." },
  [ordered]@{ Number = 16; Id = "CLZ-250"; Folder = "CLZ-250-for-each-windows-vms"; Title = "For Each Windows VMs"; Topic = "Terraform for_each with Windows VMs"; Build = "A map-driven set of named Windows VMs."; Outcomes = "Use map inputs; address resources by key; produce map outputs."; Diagram = "windows-iis-vm.svg"; Next = "Move from individual VMs to a VMSS." },
  [ordered]@{ Number = 17; Id = "CLZ-260"; Folder = "CLZ-260-windows-vmss-manual-scaling"; Title = "Windows VMSS Manual Scaling"; Topic = "Windows VMSS with IIS"; Build = "A Windows VMSS with IIS behind a Standard Load Balancer."; Outcomes = "Create VMSS network profile; install IIS across instances; change instance_count deliberately."; Diagram = "load-balancer-vmss.svg"; Next = "Add autoscale rules." },
  [ordered]@{ Number = 18; Id = "CLZ-270"; Folder = "CLZ-270-windows-vmss-autoscaling"; Title = "Windows VMSS Autoscaling"; Topic = "Autoscale rules and validation"; Build = "A Windows VMSS with CPU-based scale-out and scale-in rules."; Outcomes = "Create autoscale profiles; define thresholds; inspect scaling settings in Azure."; Diagram = "load-balancer-vmss.svg"; Next = "Control outbound access with NAT Gateway." },
  [ordered]@{ Number = 19; Id = "CLZ-280"; Folder = "CLZ-280-nat-gateway-outbound"; Title = "NAT Gateway Outbound"; Topic = "NAT Gateway for private Windows workloads"; Build = "A subnet with stable outbound access through NAT Gateway."; Outcomes = "Attach a NAT Gateway; understand egress identity; keep inbound access separate."; Diagram = "network-foundation.svg"; Next = "Add private DNS names." },
  [ordered]@{ Number = 20; Id = "CLZ-290"; Folder = "CLZ-290-private-dns"; Title = "Private DNS"; Topic = "Private DNS zones and internal names"; Build = "An internal DNS zone linked to the lab VNet."; Outcomes = "Create a private zone; link it to a VNet; add a private A record."; Diagram = "private-endpoint-sql.svg"; Next = "Optionally model public DNS." },
  [ordered]@{ Number = 21; Id = "CLZ-300"; Folder = "CLZ-300-public-dns-optional"; Title = "Public DNS Optional"; Topic = "Public DNS zone pattern"; Build = "An optional public DNS zone controlled by a boolean variable."; Outcomes = "Model optional resources; expose name server outputs; avoid creating domains accidentally."; Diagram = "network-foundation.svg"; Next = "Create remote state storage." },
  [ordered]@{ Number = 22; Id = "CLZ-310"; Folder = "CLZ-310-remote-state-storage"; Title = "Remote State Storage"; Topic = "Azure Storage backend"; Build = "A storage account and private container for shared Terraform state."; Outcomes = "Prepare backend storage; record output values; understand state separation."; Diagram = "remote-state.svg"; Next = "Read outputs from another state file." },
  [ordered]@{ Number = 23; Id = "CLZ-320"; Folder = "CLZ-320-cross-environment-state"; Title = "Cross Environment State"; Topic = "Remote state data between environments"; Build = "A data source that reads outputs from a shared state file."; Outcomes = "Configure terraform_remote_state; inspect shared outputs; avoid tight coupling."; Diagram = "remote-state.svg"; Next = "Add global routing." },
  [ordered]@{ Number = 24; Id = "CLZ-330"; Folder = "CLZ-330-traffic-manager-or-front-door"; Title = "Traffic Manager Or Front Door"; Topic = "Global routing for HTTP endpoints"; Build = "A global routing profile over configurable endpoint host names."; Outcomes = "Understand priority routing; configure endpoint monitoring; plan global failover."; Diagram = "global-routing.svg"; Next = "Move generated secrets into Key Vault." },
  [ordered]@{ Number = 25; Id = "CLZ-340"; Folder = "CLZ-340-key-vault-secrets"; Title = "Key Vault Secrets"; Topic = "Key Vault for generated admin secrets"; Build = "A Key Vault storing a generated Windows administrator password."; Outcomes = "Create vault access; write a secret; avoid exposing sensitive outputs."; Diagram = "security-secrets.svg"; Next = "Use private endpoints for platform services." },
  [ordered]@{ Number = 26; Id = "CLZ-350"; Folder = "CLZ-350-private-endpoint-storage"; Title = "Private Endpoint Storage"; Topic = "Private endpoint and private DNS for Storage"; Build = "A storage account reachable through a private endpoint."; Outcomes = "Create service connection; attach a private DNS zone group; verify private name resolution."; Diagram = "private-endpoint-sql.svg"; Next = "Add observability." },
  [ordered]@{ Number = 27; Id = "CLZ-360"; Folder = "CLZ-360-azure-monitor-log-analytics"; Title = "Azure Monitor Log Analytics"; Topic = "Monitoring, alerts, and workspace basics"; Build = "A Log Analytics workspace and action group foundation."; Outcomes = "Create the workspace; understand retention; prepare alert routing."; Diagram = "monitoring.svg"; Next = "Automate validation with GitHub Actions." },
  [ordered]@{ Number = 28; Id = "CLZ-370"; Folder = "CLZ-370-github-actions-terraform"; Title = "GitHub Actions Terraform"; Topic = "GitHub Actions plan workflow"; Build = "A workflow example that validates Terraform on Windows runners."; Outcomes = "Read workflow structure; run init without backend; validate lesson folders in CI."; Diagram = "github-actions.svg"; Next = "Build a private Azure SQL data tier." },
  [ordered]@{ Number = 29; Id = "CLZ-380"; Folder = "CLZ-380-azure-sql-private-access"; Title = "Azure SQL Private Access"; Topic = "Azure SQL with private access"; Build = "An Azure SQL database exposed through a private endpoint."; Outcomes = "Disable public access; create SQL private DNS; connect the private endpoint."; Diagram = "private-endpoint-sql.svg"; Next = "Combine the patterns in the capstone." },
  [ordered]@{ Number = 30; Id = "CLZ-390"; Folder = "CLZ-390-final-windows-reference-architecture"; Title = "Final Windows Reference Architecture"; Topic = "Modules, VMSS, Bastion, Key Vault, and monitoring"; Build = "A reusable Windows reference architecture using local modules."; Outcomes = "Compose modules; combine VMSS, Bastion, Key Vault, and monitoring; validate a full design."; Diagram = "capstone-architecture.svg"; Next = "Review, customize, and extend the lab set." }
)

$Diagrams = @{
  "terraform-workflow.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="420" viewBox="0 0 1100 420" role="img" aria-labelledby="title desc">
  <title id="title">Terraform workflow</title>
  <desc id="desc">A visual flow from authoring Terraform files to initialization, validation, planning, applying, and cleanup.</desc>
  <style>.bg{fill:#f7fafc}.box{fill:#ffffff;stroke:#1f6feb;stroke-width:3}.accent{fill:#dbeafe}.text{font:600 24px Arial,sans-serif;fill:#111827}.small{font:17px Arial,sans-serif;fill:#374151}.arrow{stroke:#0f766e;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#0f766e"/></marker></defs>
  <rect class="bg" width="1100" height="420" rx="18"/>
  <text class="text" x="40" y="55">Chriz Labz Terraform Workflow</text>
  <g transform="translate(55 115)">
    <rect class="box" width="160" height="110" rx="12"/><text class="text" x="32" y="45">Write</text><text class="small" x="24" y="78">.tf files</text>
    <line class="arrow" x1="180" y1="55" x2="245" y2="55"/>
    <rect class="box accent" x="270" width="160" height="110" rx="12"/><text class="text" x="318" y="45">Init</text><text class="small" x="300" y="78">providers</text>
    <line class="arrow" x1="450" y1="55" x2="515" y2="55"/>
    <rect class="box" x="540" width="160" height="110" rx="12"/><text class="text" x="574" y="45">Check</text><text class="small" x="568" y="78">fmt + validate</text>
    <line class="arrow" x1="720" y1="55" x2="785" y2="55"/>
    <rect class="box accent" x="810" width="160" height="110" rx="12"/><text class="text" x="860" y="45">Plan</text><text class="small" x="840" y="78">review change</text>
  </g>
  <g transform="translate(225 285)">
    <rect class="box" width="220" height="80" rx="12"/><text class="text" x="75" y="50">Apply</text>
    <line class="arrow" x1="245" y1="40" x2="365" y2="40"/>
    <rect class="box accent" x="390" width="220" height="80" rx="12"/><text class="text" x="452" y="50">Destroy</text>
  </g>
</svg>
'@
  "resource-naming.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="360" viewBox="0 0 1100 360" role="img" aria-labelledby="title desc">
  <title id="title">Naming and tags</title>
  <desc id="desc">Resource naming parts and standard Chriz Labz tags.</desc>
  <style>.bg{fill:#f8fafc}.part{fill:#eef2ff;stroke:#4f46e5;stroke-width:3}.tag{fill:#ecfdf5;stroke:#059669;stroke-width:3}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}</style>
  <rect class="bg" width="1100" height="360" rx="18"/>
  <text class="text" x="40" y="55">Resource Identity Pattern</text>
  <text class="text" x="260" y="132">clz-dev-clz220-web-lb</text>
  <g transform="translate(120 170)">
    <rect class="part" width="150" height="80" rx="12"/><text class="text" x="53" y="48">clz</text><text class="small" x="32" y="105">prefix</text>
    <rect class="part" x="180" width="150" height="80" rx="12"/><text class="text" x="228" y="48">dev</text><text class="small" x="204" y="105">environment</text>
    <rect class="part" x="360" width="150" height="80" rx="12"/><text class="text" x="400" y="48">clz220</text><text class="small" x="390" y="105">lesson</text>
    <rect class="part" x="540" width="150" height="80" rx="12"/><text class="text" x="592" y="48">web</text><text class="small" x="579" y="105">workload</text>
    <rect class="part" x="720" width="150" height="80" rx="12"/><text class="text" x="768" y="48">lb</text><text class="small" x="761" y="105">resource</text>
  </g>
  <g transform="translate(775 38)">
    <rect class="tag" width="270" height="108" rx="12"/>
    <text class="small" x="22" y="34">Project = Chriz Labz</text>
    <text class="small" x="22" y="62">ManagedBy = Terraform</text>
    <text class="small" x="22" y="90">Lab = CLZ-220</text>
  </g>
</svg>
'@
  "network-foundation.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="460" viewBox="0 0 1100 460" role="img" aria-labelledby="title desc">
  <title id="title">Network foundation</title>
  <desc id="desc">A VNet with web, app, data, and management subnets.</desc>
  <style>.bg{fill:#f8fafc}.vnet{fill:#ffffff;stroke:#2563eb;stroke-width:4}.snet{fill:#e0f2fe;stroke:#0284c7;stroke-width:3}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}</style>
  <rect class="bg" width="1100" height="460" rx="18"/>
  <text class="text" x="40" y="55">CLZ Network Foundation</text>
  <rect class="vnet" x="85" y="95" width="930" height="300" rx="18"/>
  <text class="small" x="115" y="132">VNet 10.40.0.0/16</text>
  <rect class="snet" x="140" y="165" width="180" height="145" rx="12"/><text class="text" x="188" y="225">web</text><text class="small" x="170" y="258">10.40.1.0/24</text>
  <rect class="snet" x="350" y="165" width="180" height="145" rx="12"/><text class="text" x="404" y="225">app</text><text class="small" x="380" y="258">10.40.2.0/24</text>
  <rect class="snet" x="560" y="165" width="180" height="145" rx="12"/><text class="text" x="610" y="225">data</text><text class="small" x="590" y="258">10.40.3.0/24</text>
  <rect class="snet" x="770" y="165" width="180" height="145" rx="12"/><text class="text" x="825" y="225">mgmt</text><text class="small" x="798" y="258">10.40.10.0/24</text>
</svg>
'@
  "windows-iis-vm.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="430" viewBox="0 0 1100 430" role="img" aria-labelledby="title desc">
  <title id="title">Windows IIS VM</title>
  <desc id="desc">A Windows Server VM with IIS installed by PowerShell and reachable through HTTP.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#2563eb;stroke-width:3}.win{fill:#dbeafe}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#0f766e;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#0f766e"/></marker></defs>
  <rect class="bg" width="1100" height="430" rx="18"/>
  <text class="text" x="40" y="55">Windows VM With IIS Bootstrap</text>
  <rect class="box" x="90" y="145" width="180" height="115" rx="12"/><text class="text" x="130" y="195">Internet</text><text class="small" x="132" y="225">HTTP 80</text>
  <line class="arrow" x1="290" y1="202" x2="405" y2="202"/>
  <rect class="box" x="430" y="125" width="210" height="155" rx="12"/><text class="text" x="478" y="182">Public IP</text><text class="small" x="485" y="216">Standard SKU</text>
  <line class="arrow" x1="660" y1="202" x2="775" y2="202"/>
  <rect class="box win" x="800" y="95" width="230" height="215" rx="12"/><text class="text" x="845" y="160">Windows</text><text class="text" x="875" y="195">Server</text><text class="small" x="848" y="235">IIS via PowerShell</text>
</svg>
'@
  "bastion-rdp.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="430" viewBox="0 0 1100 430" role="img" aria-labelledby="title desc">
  <title id="title">Bastion RDP access</title>
  <desc id="desc">Browser-based RDP reaches a private Windows VM through Azure Bastion.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#7c3aed;stroke-width:3}.priv{fill:#ede9fe}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#7c3aed;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#7c3aed"/></marker></defs>
  <rect class="bg" width="1100" height="430" rx="18"/>
  <text class="text" x="40" y="55">Private RDP Through Azure Bastion</text>
  <rect class="box" x="90" y="150" width="210" height="120" rx="12"/><text class="text" x="122" y="200">Azure Portal</text><text class="small" x="118" y="232">browser session</text>
  <line class="arrow" x1="320" y1="210" x2="435" y2="210"/>
  <rect class="box priv" x="460" y="120" width="230" height="180" rx="12"/><text class="text" x="505" y="190">Bastion</text><text class="small" x="498" y="225">dedicated subnet</text>
  <line class="arrow" x1="710" y1="210" x2="825" y2="210"/>
  <rect class="box" x="850" y="120" width="200" height="180" rx="12"/><text class="text" x="890" y="190">Private</text><text class="text" x="910" y="225">VM</text>
</svg>
'@
  "load-balancer-vmss.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="470" viewBox="0 0 1100 470" role="img" aria-labelledby="title desc">
  <title id="title">Load balanced Windows web tier</title>
  <desc id="desc">A Standard Load Balancer distributes HTTP traffic to Windows IIS instances and VMSS examples.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#0f766e;stroke-width:3}.pool{fill:#ccfbf1}.vm{fill:#e0f2fe;stroke:#0284c7;stroke-width:3}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#0f766e;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#0f766e"/></marker></defs>
  <rect class="bg" width="1100" height="470" rx="18"/>
  <text class="text" x="40" y="55">Windows Web Tier Behind Standard Load Balancer</text>
  <rect class="box" x="75" y="185" width="180" height="100" rx="12"/><text class="text" x="118" y="242">Client</text>
  <line class="arrow" x1="275" y1="235" x2="410" y2="235"/>
  <rect class="box pool" x="435" y="145" width="230" height="180" rx="12"/><text class="text" x="475" y="215">Standard</text><text class="text" x="472" y="250">Load Balancer</text>
  <line class="arrow" x1="685" y1="205" x2="780" y2="160"/><line class="arrow" x1="685" y1="265" x2="780" y2="315"/>
  <rect class="vm" x="805" y="105" width="210" height="110" rx="12"/><text class="text" x="845" y="155">IIS Node 1</text>
  <rect class="vm" x="805" y="270" width="210" height="110" rx="12"/><text class="text" x="845" y="320">IIS Node 2</text>
</svg>
'@
  "remote-state.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="430" viewBox="0 0 1100 430" role="img" aria-labelledby="title desc">
  <title id="title">Remote state storage</title>
  <desc id="desc">Terraform stores shared state in an Azure Storage account and reads outputs from later environments.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#1d4ed8;stroke-width:3}.state{fill:#dbeafe}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#1d4ed8;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#1d4ed8"/></marker></defs>
  <rect class="bg" width="1100" height="430" rx="18"/>
  <text class="text" x="40" y="55">Remote State And Shared Outputs</text>
  <rect class="box" x="90" y="150" width="220" height="120" rx="12"/><text class="text" x="145" y="202">Lab A</text><text class="small" x="125" y="235">writes outputs</text>
  <line class="arrow" x1="330" y1="210" x2="450" y2="210"/>
  <rect class="box state" x="475" y="120" width="250" height="180" rx="12"/><text class="text" x="515" y="190">Azure Storage</text><text class="small" x="535" y="225">state container</text>
  <line class="arrow" x1="745" y1="210" x2="865" y2="210"/>
  <rect class="box" x="890" y="150" width="170" height="120" rx="12"/><text class="text" x="935" y="202">Lab B</text><text class="small" x="918" y="235">reads outputs</text>
</svg>
'@
  "global-routing.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="430" viewBox="0 0 1100 430" role="img" aria-labelledby="title desc">
  <title id="title">Global routing</title>
  <desc id="desc">A global routing profile sends users to primary and secondary HTTP endpoints.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#9333ea;stroke-width:3}.route{fill:#f3e8ff}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#9333ea;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#9333ea"/></marker></defs>
  <rect class="bg" width="1100" height="430" rx="18"/>
  <text class="text" x="40" y="55">Global HTTP Routing Pattern</text>
  <rect class="box" x="95" y="165" width="190" height="100" rx="12"/><text class="text" x="140" y="225">Users</text>
  <line class="arrow" x1="305" y1="215" x2="430" y2="215"/>
  <rect class="box route" x="455" y="130" width="240" height="170" rx="12"/><text class="text" x="500" y="195">Routing</text><text class="small" x="500" y="230">priority or failover</text>
  <line class="arrow" x1="715" y1="190" x2="835" y2="145"/><line class="arrow" x1="715" y1="240" x2="835" y2="300"/>
  <rect class="box" x="860" y="100" width="185" height="95" rx="12"/><text class="text" x="895" y="158">Primary</text>
  <rect class="box" x="860" y="265" width="185" height="95" rx="12"/><text class="text" x="878" y="323">Secondary</text>
</svg>
'@
  "security-secrets.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="430" viewBox="0 0 1100 430" role="img" aria-labelledby="title desc">
  <title id="title">Secrets flow</title>
  <desc id="desc">Terraform generates a password and stores it in Key Vault for later Windows resources.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#be123c;stroke-width:3}.vault{fill:#ffe4e6}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#be123c;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#be123c"/></marker></defs>
  <rect class="bg" width="1100" height="430" rx="18"/>
  <text class="text" x="40" y="55">Generated Secret Handling</text>
  <rect class="box" x="95" y="155" width="220" height="120" rx="12"/><text class="text" x="125" y="205">random_password</text><text class="small" x="150" y="238">sensitive value</text>
  <line class="arrow" x1="335" y1="215" x2="455" y2="215"/>
  <rect class="box vault" x="480" y="125" width="240" height="180" rx="12"/><text class="text" x="535" y="195">Key Vault</text><text class="small" x="535" y="230">secret storage</text>
  <line class="arrow" x1="740" y1="215" x2="860" y2="215"/>
  <rect class="box" x="885" y="155" width="175" height="120" rx="12"/><text class="text" x="925" y="205">Windows</text><text class="small" x="922" y="238">admin access</text>
</svg>
'@
  "private-endpoint-sql.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="470" viewBox="0 0 1100 470" role="img" aria-labelledby="title desc">
  <title id="title">Private endpoint service access</title>
  <desc id="desc">Private DNS resolves a platform service to a private endpoint inside the VNet.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#0e7490;stroke-width:3}.zone{fill:#cffafe}.svc{fill:#ecfeff}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#0e7490;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#0e7490"/></marker></defs>
  <rect class="bg" width="1100" height="470" rx="18"/>
  <text class="text" x="40" y="55">Private Endpoint And Private DNS</text>
  <rect class="box" x="80" y="160" width="210" height="120" rx="12"/><text class="text" x="125" y="212">Workload</text><text class="small" x="120" y="245">inside VNet</text>
  <line class="arrow" x1="310" y1="220" x2="430" y2="220"/>
  <rect class="box zone" x="455" y="95" width="230" height="110" rx="12"/><text class="text" x="500" y="150">Private DNS</text>
  <rect class="box" x="455" y="255" width="230" height="110" rx="12"/><text class="text" x="500" y="313">Endpoint</text>
  <line class="arrow" x1="705" y1="310" x2="825" y2="310"/>
  <rect class="box svc" x="850" y="230" width="200" height="160" rx="12"/><text class="text" x="905" y="295">Azure</text><text class="text" x="885" y="330">Service</text>
</svg>
'@
  "monitoring.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="430" viewBox="0 0 1100 430" role="img" aria-labelledby="title desc">
  <title id="title">Monitoring foundation</title>
  <desc id="desc">Azure resources send operational signals to Log Analytics and alert routing.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#ca8a04;stroke-width:3}.log{fill:#fef3c7}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#ca8a04;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#ca8a04"/></marker></defs>
  <rect class="bg" width="1100" height="430" rx="18"/>
  <text class="text" x="40" y="55">Observability Foundation</text>
  <rect class="box" x="95" y="155" width="220" height="120" rx="12"/><text class="text" x="145" y="205">Azure</text><text class="small" x="135" y="238">resource signals</text>
  <line class="arrow" x1="335" y1="215" x2="455" y2="215"/>
  <rect class="box log" x="480" y="125" width="240" height="180" rx="12"/><text class="text" x="522" y="195">Log Analytics</text><text class="small" x="535" y="230">query + retention</text>
  <line class="arrow" x1="740" y1="215" x2="860" y2="215"/>
  <rect class="box" x="885" y="155" width="175" height="120" rx="12"/><text class="text" x="925" y="205">Alerts</text><text class="small" x="915" y="238">action group</text>
</svg>
'@
  "github-actions.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="430" viewBox="0 0 1100 430" role="img" aria-labelledby="title desc">
  <title id="title">GitHub Actions validation</title>
  <desc id="desc">A GitHub Actions workflow checks Terraform formatting and validation on each change.</desc>
  <style>.bg{fill:#f8fafc}.box{fill:#fff;stroke:#111827;stroke-width:3}.ci{fill:#e5e7eb}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#111827;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#111827"/></marker></defs>
  <rect class="bg" width="1100" height="430" rx="18"/>
  <text class="text" x="40" y="55">Repository Validation Flow</text>
  <rect class="box" x="95" y="155" width="190" height="120" rx="12"/><text class="text" x="138" y="205">Commit</text><text class="small" x="128" y="238">docs + HCL</text>
  <line class="arrow" x1="305" y1="215" x2="430" y2="215"/>
  <rect class="box ci" x="455" y="125" width="240" height="180" rx="12"/><text class="text" x="510" y="195">Actions</text><text class="small" x="505" y="230">fmt + validate</text>
  <line class="arrow" x1="715" y1="215" x2="840" y2="215"/>
  <rect class="box" x="865" y="155" width="170" height="120" rx="12"/><text class="text" x="913" y="205">Pass</text><text class="small" x="900" y="238">ready to run</text>
</svg>
'@
  "capstone-architecture.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="620" viewBox="0 0 1200 620" role="img" aria-labelledby="title desc">
  <title id="title">Capstone Windows reference architecture</title>
  <desc id="desc">The capstone combines network, Windows VMSS, load balancing, Bastion, Key Vault, and monitoring.</desc>
  <style>.bg{fill:#f8fafc}.vnet{fill:#fff;stroke:#2563eb;stroke-width:4}.box{fill:#fff;stroke:#0f766e;stroke-width:3}.sec{fill:#ffe4e6;stroke:#be123c;stroke-width:3}.obs{fill:#fef3c7;stroke:#ca8a04;stroke-width:3}.net{fill:#dbeafe;stroke:#2563eb;stroke-width:3}.text{font:700 24px Arial,sans-serif;fill:#111827}.small{font:18px Arial,sans-serif;fill:#374151}.arrow{stroke:#0f766e;stroke-width:4;marker-end:url(#arrow)}</style>
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#0f766e"/></marker></defs>
  <rect class="bg" width="1200" height="620" rx="18"/>
  <text class="text" x="40" y="55">CLZ-390 Windows Reference Architecture</text>
  <rect class="vnet" x="70" y="95" width="1060" height="410" rx="18"/>
  <text class="small" x="100" y="130">Chriz Labz VNet</text>
  <rect class="net" x="120" y="165" width="220" height="120" rx="12"/><text class="text" x="165" y="215">Bastion</text><text class="small" x="150" y="248">private RDP path</text>
  <rect class="box" x="455" y="145" width="260" height="160" rx="12"/><text class="text" x="497" y="205">Standard LB</text><text class="small" x="505" y="240">HTTP frontend</text>
  <line class="arrow" x1="735" y1="225" x2="815" y2="225"/>
  <rect class="box" x="835" y="135" width="240" height="180" rx="12"/><text class="text" x="884" y="200">Windows</text><text class="text" x="882" y="235">IIS VMSS</text>
  <rect class="sec" x="120" y="340" width="260" height="110" rx="12"/><text class="text" x="165" y="405">Key Vault</text>
  <rect class="obs" x="455" y="340" width="260" height="110" rx="12"/><text class="text" x="498" y="405">Monitoring</text>
  <rect class="net" x="835" y="340" width="240" height="110" rx="12"/><text class="text" x="880" y="405">Modules</text>
</svg>
'@
  "curriculum-map.svg" = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="520" viewBox="0 0 1200 520" role="img" aria-labelledby="title desc">
  <title id="title">Chriz Labz curriculum map</title>
  <desc id="desc">The curriculum progresses from foundations to network, Windows compute, state, security, automation, data, and capstone.</desc>
  <style>.bg{fill:#f8fafc}.lane{fill:#fff;stroke:#cbd5e1;stroke-width:2}.step{fill:#dbeafe;stroke:#2563eb;stroke-width:3}.adv{fill:#ecfdf5;stroke:#059669;stroke-width:3}.text{font:700 23px Arial,sans-serif;fill:#111827}.small{font:17px Arial,sans-serif;fill:#374151}</style>
  <rect class="bg" width="1200" height="520" rx="18"/>
  <text class="text" x="40" y="55">30-Lesson Learning Path</text>
  <rect class="lane" x="60" y="95" width="1080" height="360" rx="16"/>
  <g transform="translate(95 135)">
    <rect class="step" width="180" height="95" rx="12"/><text class="text" x="36" y="42">100-160</text><text class="small" x="30" y="70">foundations</text>
    <rect class="step" x="210" width="180" height="95" rx="12"/><text class="text" x="247" y="42">170-180</text><text class="small" x="258" y="70">network</text>
    <rect class="step" x="420" width="180" height="95" rx="12"/><text class="text" x="457" y="42">190-270</text><text class="small" x="462" y="70">Windows</text>
    <rect class="adv" x="630" width="180" height="95" rx="12"/><text class="text" x="667" y="42">280-350</text><text class="small" x="665" y="70">platform</text>
    <rect class="adv" x="840" width="180" height="95" rx="12"/><text class="text" x="877" y="42">360-390</text><text class="small" x="875" y="70">operate</text>
  </g>
  <text class="small" x="115" y="330">The lessons are deployable one at a time. Later lessons intentionally reuse patterns from earlier labs.</text>
</svg>
'@
}

foreach ($diagramName in $Diagrams.Keys) {
  Write-LabFile -RelativePath "assets/diagrams/$diagramName" -Content $Diagrams[$diagramName]
}

$lessonRows = ($Lessons | ForEach-Object { "| $($_.Number) | [$($_.Id)]($($_.Folder)/README.md) | $($_.Title) | $($_.Topic) |" }) -join "`r`n"
$rootReadme = @'
# Chriz Labz

![Chriz Labz curriculum map](assets/diagrams/curriculum-map.svg)

Chriz Labz is an original Windows-focused Azure Terraform lab library. It starts with the Terraform workflow, then builds Azure networking, Windows Server, IIS, Bastion RDP, Load Balancer, VM Scale Sets, remote state, Key Vault, private endpoints, Azure SQL, monitoring, GitHub Actions, and a capstone reference architecture.

## What Makes This Lab Set Different
- Windows-only implementation path using PowerShell and Windows Server 2022.
- Each lesson is independently deployable and includes cleanup guidance.
- The curriculum uses original names, diagrams, explanations, and Terraform structure.
- The examples use generated secrets and safe `terraform.tfvars.example` files.
- The later lessons move from direct public access toward Bastion, Key Vault, and private endpoints.

## Visual Learning Path

| Phase | Lessons | Outcome |
|---|---:|---|
| Foundations | 100-160 | Terraform workflow, providers, naming, variables, state basics |
| Network | 170-180 | VNet, subnets, NSGs, address planning |
| Windows Compute | 190-270 | Windows VM, IIS, Bastion, Load Balancer, VMSS, autoscale |
| Platform Services | 280-350 | NAT Gateway, DNS, remote state, global routing, Key Vault, private endpoints |
| Operations | 360-390 | Monitoring, GitHub Actions, Azure SQL, final reference architecture |

## Defaults
- Region: `eastus2`
- Prefix: `clz`
- Environments: `dev`, `test`, `prod`
- OS image: Windows Server 2022 Azure Edition
- Web server: IIS
- Automation shell: PowerShell
- Admin path: Azure Bastion RDP after the Bastion lesson

## Curriculum

| Lesson | Link | Name | Topic |
|---:|---|---|---|
{{LESSON_ROWS}}

## Architecture Gallery

| Pattern | Diagram |
|---|---|
| Terraform workflow | ![Terraform workflow](assets/diagrams/terraform-workflow.svg) |
| Network foundation | ![Network foundation](assets/diagrams/network-foundation.svg) |
| Windows IIS VM | ![Windows IIS VM](assets/diagrams/windows-iis-vm.svg) |
| Bastion RDP | ![Bastion RDP](assets/diagrams/bastion-rdp.svg) |
| Load-balanced Windows tier | ![Load-balanced Windows tier](assets/diagrams/load-balancer-vmss.svg) |
| Remote state | ![Remote state](assets/diagrams/remote-state.svg) |
| Private endpoint | ![Private endpoint](assets/diagrams/private-endpoint-sql.svg) |
| Capstone | ![Capstone architecture](assets/diagrams/capstone-architecture.svg) |

## Standard Runbook

~~~powershell
terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform destroy
~~~

## Repo Checks

~~~powershell
.\scripts\Initialize-ChrizLabzWorkspace.ps1
.\scripts\Test-ChrizLabzTerraform.ps1
~~~

## Cost And Cleanup
Many lessons create paid Azure resources. Use a small `instance_count`, keep the default `eastus2` only if it fits your quota, and run `terraform destroy` after each lab unless the next lesson needs its outputs.

## References
- [Terraform core concepts](wiki/terraform-core-concepts.md)
- [Azure networking glossary](wiki/azure-networking-glossary.md)
- [Windows VM and VMSS notes](wiki/windows-vm-and-vmss-notes.md)
- [State backend and locking](wiki/state-backend-and-locking.md)
- [Security and secrets](wiki/security-and-secrets.md)
- [Troubleshooting](wiki/troubleshooting.md)
'@
Write-LabFile -RelativePath "README.md" -Content (Expand-Template -Template $rootReadme -Values @{ LESSON_ROWS = $lessonRows })

$lessonTemplate = @'
# {{ID}} - {{TITLE}}

![{{TITLE}} architecture](../assets/diagrams/{{DIAGRAM}})

## Overview
{{BUILD}}

This lesson is part of the Windows-only Chriz Labz path. It keeps the configuration readable, uses the shared naming model, and avoids hidden prerequisites beyond Azure CLI authentication and Terraform.

## What You Build
| Item | Description |
|---|---|
| Main topic | {{TOPIC}} |
| Azure scope | One resource group tagged for this lesson |
| Default region | `eastus2` |
| Naming style | `clz-dev-{{LOCAL_CODE}}-*` |
| Cleanup path | `terraform destroy` from this folder |

## Learning Outcomes
{{OUTCOMES}}

## Files In This Lab
| File | Purpose |
|---|---|
| `versions.tf` | Terraform and provider constraints |
| `providers.tf` | AzureRM provider configuration |
| `variables.tf` | Inputs shared across the curriculum |
| `locals.tf` | Naming and tag composition |
| `resource-group.tf` | Lesson resource group |
| `{{FOCUS_FILE}}` | Lesson-specific Azure resources |
| `outputs.tf` | Values used for validation |
| `terraform.tfvars.example` | Safe example inputs |

## Runbook
1. Open this folder in PowerShell.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` only if you need local overrides.
3. Run `terraform init`.
4. Run `terraform fmt -check`.
5. Run `terraform validate`.
6. Run `terraform plan -out tfplan`.
7. Review the plan, then run `terraform apply tfplan`.
8. Capture `terraform output` values needed for validation.

## Validation Checklist
- Resource names start with `clz-dev-{{LOCAL_CODE}}`.
- Tags include `Project`, `Environment`, `ManagedBy`, and `Lab`.
- Outputs match the resources created by the plan.
- No local secrets are committed.

## Cleanup
Run `terraform destroy` from this folder. If the lab created shared values for the next lesson, record the outputs first.

## Next Lesson
{{NEXT}}
'@

foreach ($lesson in $Lessons) {
  $localCode = ($lesson.Id -replace "CLZ-", "clz").ToLowerInvariant()
  $focusFile = switch -Wildcard ($lesson.Folder) {
    "*virtual-network*" { "network.tf" }
    "*network-security*" { "security.tf" }
    "*windows-vm-basics" { "compute-windows.tf" }
    "*iis-bootstrap" { "compute-windows.tf" }
    "*bastion*" { "bastion.tf" }
    "*standard-load-balancer*" { "load-balancer.tf" }
    "*nat-rules*" { "load-balancer-nat.tf" }
    "*count*" { "compute-count.tf" }
    "*for-each*" { "compute-for-each.tf" }
    "*manual-scaling*" { "vmss.tf" }
    "*autoscaling*" { "autoscale.tf" }
    "*nat-gateway*" { "nat-gateway.tf" }
    "*private-dns" { "private-dns.tf" }
    "*public-dns*" { "public-dns.tf" }
    "*remote-state-storage*" { "state-storage.tf" }
    "*cross-environment*" { "remote-state-data.tf" }
    "*traffic-manager*" { "traffic-manager.tf" }
    "*key-vault*" { "key-vault.tf" }
    "*private-endpoint*" { "private-endpoint.tf" }
    "*monitor*" { "monitoring.tf" }
    "*github-actions*" { "workflow-support.tf" }
    "*azure-sql*" { "azure-sql.tf" }
    "*final-windows*" { "capstone.tf" }
    default { "lab.tf" }
  }

  $values = @{
    ID         = $lesson.Id
    TITLE      = $lesson.Title
    TOPIC      = $lesson.Topic
    BUILD      = $lesson.Build
    OUTCOMES   = $lesson.Outcomes
    DIAGRAM    = $lesson.Diagram
    NEXT       = $lesson.Next
    LOCAL_CODE = $localCode
    FOCUS_FILE = $focusFile
  }
  Write-LabFile -RelativePath "$($lesson.Folder)/README.md" -Content (Expand-Template -Template $lessonTemplate -Values $values)
}

Write-LabFile -RelativePath "wiki/terraform-core-concepts.md" -Content @'
# Terraform Core Concepts

![Terraform workflow](../assets/diagrams/terraform-workflow.svg)

Terraform is a desired-state workflow. You write the target shape of Azure resources, Terraform compares that configuration with state and provider data, then it proposes changes.

## Command Flow
| Command | Purpose | When to use |
|---|---|---|
| `terraform init` | Downloads providers and prepares the folder | First run and after provider/module/backend changes |
| `terraform fmt -check` | Confirms consistent formatting | Before every commit |
| `terraform validate` | Checks configuration structure | Before planning |
| `terraform plan -out tfplan` | Creates a reviewed execution plan | Before every apply |
| `terraform apply tfplan` | Applies the reviewed plan | Only after plan review |
| `terraform destroy` | Removes resources in this state | End of each lab |

## File Roles
| File | Why it exists |
|---|---|
| `versions.tf` | Provider and Terraform constraints |
| `providers.tf` | Azure provider setup |
| `variables.tf` | Inputs that should be easy to change |
| `locals.tf` | Derived names, compact prefixes, and tags |
| `outputs.tf` | Values used for validation or later lessons |

## Review Habit
Read every plan for create, update, and destroy actions. A good lab run has a small, understandable plan and a clear cleanup step.
'@

Write-LabFile -RelativePath "wiki/azure-networking-glossary.md" -Content @'
# Azure Networking Glossary

![Network foundation](../assets/diagrams/network-foundation.svg)

## Core Terms
| Term | Meaning in Chriz Labz |
|---|---|
| Resource group | Boundary for one lab deployment |
| VNet | Private address space for lab resources |
| Subnet | Smaller network segment for a workload role |
| NSG | Rule set for subnet or NIC traffic |
| Public IP | Internet-facing endpoint used only where intentional |
| Load Balancer | Layer 4 distribution for HTTP or admin NAT patterns |
| NAT Gateway | Stable outbound access for private subnets |
| Private DNS | Internal name resolution linked to VNets |
| Private Endpoint | Private network entry point for an Azure platform service |

## Standard Subnet Model
| Subnet | CIDR | Use |
|---|---|---|
| web | `10.40.1.0/24` | IIS front-end and VMSS examples |
| app | `10.40.2.0/24` | Application tier expansion |
| data | `10.40.3.0/24` | Private endpoints and database access |
| mgmt | `10.40.10.0/24` | Management and operations patterns |

## Design Rule
Prefer private access for admin and data paths. Use public endpoints only when the lesson explicitly teaches public routing.
'@

Write-LabFile -RelativePath "wiki/windows-vm-and-vmss-notes.md" -Content @'
# Windows VM And VMSS Notes

![Windows IIS VM](../assets/diagrams/windows-iis-vm.svg)

## Image Standard
Chriz Labz uses Windows Server 2022 Azure Edition by default:

| Field | Value |
|---|---|
| Publisher | `MicrosoftWindowsServer` |
| Offer | `WindowsServer` |
| SKU | `2022-datacenter-azure-edition` |
| Version | `latest` |

## Access Pattern
Early labs use direct access only where it helps explain the resource. The preferred operating model is Azure Bastion RDP to private Windows VMs.

![Bastion RDP](../assets/diagrams/bastion-rdp.svg)

## IIS Bootstrap
IIS examples use PowerShell through Custom Script Extension. The validation page is written to `C:\inetpub\wwwroot\index.html`.

## VMSS Pattern
Windows VMSS lessons use a Standard Load Balancer, an HTTP probe, and an extension that installs IIS across instances.

![Load-balanced Windows tier](../assets/diagrams/load-balancer-vmss.svg)
'@

Write-LabFile -RelativePath "wiki/state-backend-and-locking.md" -Content @'
# State Backend And Locking

![Remote state](../assets/diagrams/remote-state.svg)

Terraform state is the map between configuration and Azure resource IDs. It is operational data, not documentation.

## Local State
Early lessons use local state so the workflow stays easy to inspect. Local state is acceptable for isolated practice, but it should not be committed.

## Remote State
The remote-state lesson creates an Azure Storage account and private container. Later lessons can read selected outputs from that state file.

## State Safety Checklist
| Rule | Reason |
|---|---|
| Keep one state per lab or environment | Prevent accidental cross-environment changes |
| Do not edit state manually | Manual edits can break resource tracking |
| Do not commit state files | State may contain sensitive or operational data |
| Destroy from the owning folder | Terraform needs the matching configuration and state |
| Record outputs before cleanup | Later lessons may need storage account or endpoint values |

## Backend Shape
The backend uses a storage account, a private container, and one key per environment. The example key pattern is `clz-dev.tfstate`.
'@

Write-LabFile -RelativePath "wiki/security-and-secrets.md" -Content @'
# Security And Secrets

![Generated secret handling](../assets/diagrams/security-secrets.svg)

## Secret Rules
| Rule | Practice |
|---|---|
| Generate credentials | Use `random_password` for lab credentials |
| Mark outputs sensitive | Prevent casual terminal exposure |
| Keep real values local | Use `terraform.tfvars`, not committed files |
| Store later secrets centrally | Use Key Vault once introduced |

## Network Rules
Use narrow admin CIDR values and prefer Bastion for private RDP. Public endpoints are kept for specific teaching goals such as HTTP validation or load-balancing behavior.

## Private Platform Access
Private Endpoint lessons move storage and database access onto the VNet. Private DNS then resolves service names to private addresses.

![Private endpoint service access](../assets/diagrams/private-endpoint-sql.svg)
'@

Write-LabFile -RelativePath "wiki/troubleshooting.md" -Content @'
# Troubleshooting

## Fast Checks
| Symptom | Check | Typical Fix |
|---|---|---|
| Provider cannot authenticate | `az account show` | Sign in again or set `subscription_id` |
| Provider not installed | `terraform init` | Reinitialize the folder |
| Formatting check fails | `terraform fmt` | Review and commit formatting changes |
| Name conflict | Azure error mentions existing name | Change `name_prefix` or `environment` |
| VM quota error | Azure error mentions quota or SKU | Lower `instance_count` or choose another size |
| Destroy fails once | Rerun `terraform destroy` | Some Azure deletes are eventually consistent |

## Visual Triage

![Monitoring foundation](../assets/diagrams/monitoring.svg)

Start with the smallest failing scope: current folder, current state, current Azure resource group. The `Lab` tag identifies resources created by each lesson.

## Useful Commands
~~~powershell
az account show
terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform output
terraform destroy
~~~
'@

Write-LabFile -RelativePath "assets/README.md" -Content @'
# Assets

This folder contains original SVG diagrams used by the Chriz Labz README files and wiki pages.

## Diagram Index
| Diagram | Used for |
|---|---|
| `curriculum-map.svg` | Root curriculum overview |
| `terraform-workflow.svg` | Terraform command sequence |
| `resource-naming.svg` | Naming and tagging standards |
| `network-foundation.svg` | VNet and subnet model |
| `windows-iis-vm.svg` | Windows VM with IIS |
| `bastion-rdp.svg` | Private RDP through Bastion |
| `load-balancer-vmss.svg` | Load Balancer and VMSS patterns |
| `remote-state.svg` | Azure Storage-backed state |
| `private-endpoint-sql.svg` | Private Endpoint and DNS |
| `security-secrets.svg` | Key Vault secret flow |
| `monitoring.svg` | Observability foundation |
| `github-actions.svg` | Repository validation workflow |
| `capstone-architecture.svg` | Final reference architecture |
'@

Write-LabFile -RelativePath ".gitignore" -Content @'
# Terraform runtime data
**/.terraform/*
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log

# Local values and overrides
terraform.tfvars
*.auto.tfvars
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Local editor and OS noise
.vscode/
.idea/
Thumbs.db
.DS_Store
'@

Write-LabFile -RelativePath ".github/workflows/terraform-validate.yml" -Content @'
name: terraform-validate

on:
  workflow_dispatch:
  pull_request:
  push:
    branches:
      - main

jobs:
  validate:
    runs-on: windows-latest
    defaults:
      run:
        shell: pwsh

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Format
        run: terraform fmt -check -recursive

      - name: Validate lesson folders
        run: |
          $folders = Get-ChildItem -Directory -Filter "CLZ-*"
          foreach ($folder in $folders) {
            Push-Location $folder.FullName
            try {
              terraform init -backend=false -input=false
              terraform validate
            }
            finally {
              Pop-Location
            }
          }
'@

Write-LabFile -RelativePath "CONTRIBUTING.md" -Content @'
# Contributing

Chriz Labz is organized as small, readable Terraform lessons. Keep contributions focused and easy to validate.

## Standards
- Use PowerShell examples.
- Keep lesson folders independently deployable.
- Commit only safe example values.
- Run `terraform fmt -check -recursive`.
- Run `.\scripts\Test-ChrizLabzTerraform.ps1` before pushing broad Terraform changes.

## Documentation
Every lesson README should include a goal, architecture image, build summary, runbook, validation checklist, cleanup note, and next lesson pointer.
'@

Write-Host "Chriz Labz documentation enriched."
