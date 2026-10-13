"""Ten original workstation, Terraform, and network teaching scenes."""


def workstation(d, item):
    d.group('Local workstation',350,165,500,460)
    d.node('audit','Readiness audit','check',470,225,260,150,'versions + PATH')
    d.node('shell','PowerShell 7','terminal',470,420,260,165,'one command surface')
    d.node('git','Git','git',70,215,220,150,'retrieve + version')
    d.node('editor','VS Code','plan',70,435,220,150,'edit + extensions')
    d.node('terraform','Terraform CLI','tf',910,215,220,150,'local language tools')
    d.node('cli','Azure CLI','cloud',910,435,220,150,'identity in later labs')
    d.edge('audit','shell','check tools',style='dotted',label_pos=(760,397))
    d.edge('git','shell',style='dashed')
    d.edge('editor','shell',style='dashed')
    d.edge('shell','terraform',style='dashed')
    d.edge('shell','cli',style='dashed')
    d.note('Optional preparation only. This lesson declares no cloud provider and never contacts Azure.\nAfter installation, reopen PowerShell so new PATH entries are available.',width=100)


def expressions(d, item):
    d.group('Three harmless inputs',40,160,300,465)
    d.node('environment','dev','tag',70,210,240,120,'environment')
    d.node('prefix','clz','plan',70,350,240,120,'name_prefix')
    d.node('region','eastus2','dns',70,490,240,120,'location preview')
    d.node('locals','Naming + tags','tf',465,305,250,175,'derived expressions')
    d.node('preview','Planned output','plan',895,305,265,175,'configuration_preview')
    d.edge('environment','locals',points=[(390,270),(390,345)])
    d.edge('prefix','locals')
    d.edge('region','locals',points=[(390,550),(390,445)])
    d.edge('locals','preview','evaluate',label_pos=(805,380))
    d.text('clz-dev-clz100-rg',475,550,29,color='#60e0e5',width=35,weight=700)
    d.text('terraform show tfplan',890,550,22,width=30)
    d.note('A preview is not a deployed resource. There is no provider, backend, data source, or resource.\nRead planned outputs with terraform show tfplan; terraform output reads outputs already in state.',width=105)


def readiness(d, item):
    d.group('Azure metadata · inspection only',380,160,790,465)
    d.node('cli','Azure CLI context','terminal',60,330,250,175,'selected account')
    d.node('tenant','Tenant ID','user',435,220,260,155,'intended directory')
    d.node('subscription','Subscription ID','cloud',870,220,260,155,'Enabled + intended')
    d.node('region','Region','dns',435,455,260,155,'location is available')
    d.node('checks','Roles + quota','shield',870,455,260,155,'scope + VM capacity')
    d.edge('cli','tenant','read context',style='dotted',label_pos=(320,265))
    d.edge('tenant','subscription','compare IDs',style='dotted')
    d.edge('subscription','checks','inspect',style='dotted')
    d.edge('cli','region',style='dotted',label_pos=(340,540))
    d.note('Terraform emits readiness commands locally; run the CLI checks explicitly from PowerShell.\nSelect by subscription GUID. The checks deploy, register, and delete nothing in Azure.',width=105)


def first_deployment(d, item):
    d.text('1 · Review the proposal',65,215,24,color='#b39bff',width=28,weight=700)
    d.text('2 · Apply deliberately',450,215,24,color='#60e0e5',width=28,weight=700)
    d.text('3 · Verify the binding',875,215,24,color='#61caff',width=28,weight=700)
    d.node('plan','Saved plan','plan',60,275,270,180,'+ resource group')
    d.node('group','Azure resource group','folder',470,275,260,180,'name + region + tags')
    d.node('state','Local state','storage',900,275,240,180,'resource address ↔ ID')
    d.edge('plan','group','apply tfplan',label_pos=(400,350))
    d.edge('group','state','record ID',label_pos=(815,350))
    d.icon('search',495,525,64)
    d.text('az group show',585,555,24,width=25)
    d.icon('trash',920,525,64,color='#b39bff')
    d.text('destroy + audit',1000,555,21,width=17)
    d.note('This lesson creates one tagged resource group, with no chargeable workload inside it.\nCleanup is complete when Terraform state is empty and az group exists returns false.',width=105)


def authentication(d, item):
    d.group('Identity answers: who?',35,165,550,245)
    d.group('Azure target answers: where?',625,165,540,245)
    d.node('human','Signed-in user','user',55,225,210,150,'az login')
    d.node('token','CLI access token','key',335,225,220,150,'tenant context')
    d.node('provider','AzureRM provider','tf',650,225,220,150,'CLI authentication')
    d.node('subscription','Subscription GUID','cloud',940,225,205,150,'target input')
    d.node('scope','Role at scope','shield',470,465,260,150,'authorized operations')
    d.edge('human','token','sign in',style='dotted')
    d.edge('token','provider','authenticate',label_pos=(603,430))
    d.edge('provider','subscription','target',label_pos=(905,315))
    d.edge('provider','scope','authorize',style='dotted',label_pos=(800,445))
    d.note('Authentication and authorization are separate checks. Login does not grant deployment rights.\nThe provider subscription_id must match the intended subscription and identity context.',width=104)


def tags(d, item):
    d.group('One owned resource group',300,165,600,460)
    d.node('group','clz-dev-clz140-rg','folder',435,220,330,175,'location: eastus2')
    d.node('project','Project','tag',65,210,205,150,'Azure From Zero To Hero')
    d.node('environment','Environment','tag',65,440,205,150,'dev / test / prod')
    d.node('managed','ManagedBy','tag',930,210,205,150,'Terraform')
    d.node('lab','Lab','tag',930,440,205,150,'CLZ-140')
    d.edge('project','group')
    d.edge('environment','group',points=[(340,515),(340,365)])
    d.edge('managed','group')
    d.edge('lab','group',points=[(865,515),(865,365)])
    d.text('A label is metadata',415,490,29,color='#60e0e5',width=32,weight=700)
    d.text('Use tags to find ownership and organize costs.',365,540,22,width=44)
    d.note('Tags do not grant permissions or automatically copy to resources created inside a group.\nThe Lab value is fixed by the lesson; environment and prefix are learner inputs.',width=103)


def interface(d, item):
    d.node('inputs','Typed inputs','plan',40,220,235,180,'prefix · environment\nlocation · subscription')
    d.node('locals','Derived locals','tf',330,220,240,180,'fixed lab ID\nprefix + tag map')
    d.node('group','Managed group','folder',625,220,240,180,'name · location\nstandard tags')
    d.node('outputs','Outputs','search',920,220,240,180,'group name\nlocation')
    d.edge('inputs','locals')
    d.edge('locals','group')
    d.edge('group','outputs')
    d.group('An interface you can trace',140,460,920,155)
    d.icon('tag',175,510,55,color='#b39bff')
    d.text('Change a valid environment → inspect the new name and tags in the plan.',255,535,23,width=65)
    d.note('Variables are the public interface; locals derive values; outputs expose validation results.\nCLZ-150 remains fixed. Outputs read managed values after apply, rather than creating resources.',width=107)


def state_binding(d, item):
    d.group('Workstation · local backend',40,160,520,465)
    d.group('Azure · one managed object',700,160,460,465)
    d.node('writer','Terraform process','terminal',70,230,205,150,'one writer')
    d.node('lock','Local state lock','lock',330,230,205,150,'short-lived guard')
    d.node('state','terraform.tfstate','storage',170,450,280,155,'address → Azure ID')
    d.node('group','Resource group','folder',805,325,255,175,'same ID + tags')
    d.edge('writer','lock','acquire',label_pos=(305,220))
    d.edge('lock','state',points=[(460,420),(400,420)])
    d.edge('state','group','refresh / compare',style='dotted',points=[(610,525),(610,405)],label_pos=(640,510))
    d.note('This lesson uses local state. Azure Storage and blob-lease locking arrive in CLZ-310.\nNever delete state to hide drift; recover or import the known object before cleanup.',width=106)


def cidr_map(d, item):
    d.group('Tagged resource group · one VNet',40,160,1120,470)
    d.node('vnet','Virtual network','network',450,220,300,155,'10.40.0.0/16')
    subnets = [('web','web-snet','10.40.1.0/24'),('app','app-snet','10.40.2.0/24'),('data','data-snet','10.40.3.0/24'),('mgmt','mgmt-snet','10.40.10.0/24')]
    for index,(id,label,cidr) in enumerate(subnets):
        x=65+index*280
        d.node(id,label,'network',x,460,230,150,cidr)
        d.edge('vnet',id,points=[(600,415),(x+115,415)])
    d.note('CIDRs allocate separate, nonoverlapping address ranges inside the VNet. This is not a scale drawing.\nNo VM, NSG, route table, public IP, or firewall is created by this lesson.',width=110)


def nsg_decisions(d, item):
    d.group('NSG · first matching rule',380,155,440,480)
    rows = [(195,'http','HTTP request','Internet → TCP 80','100 · Allow HTTP','Internet / port 80'),(345,'admin','Admin request','admin_cidr → 3389','110 · Allow RDP','one IPv4 /32'),(495,'other','Other RDP','any other source','120 · Deny RDP','any / port 3389')]
    for y,id,label,detail,rule,rule_detail in rows:
        d.node(id,label,'terminal',50,y,260,130,detail)
        d.node(id+'rule',rule,'shield',420,y,360,130,rule_detail)
        d.edge(id,id+'rule')
    d.node('web','web-snet','network',915,245,235,175,'NSG association')
    d.node('blocked','Blocked','lock',935,505,215,125,'RDP denied')
    d.edge('httprule','web','allowed',points=[(860,260),(860,292)],label_pos=(864,217))
    d.edge('adminrule','web','allowed',points=[(870,410),(870,365)],label_pos=(855,455))
    d.edge('otherrule','blocked','denied')
    d.note('These are rule-decision examples; no VM or reachable RDP service is deployed in CLZ-180.\nThe /32 validator checks address format. Verify the real public source address yourself.',width=105)


SCENES = {
    'CLZ-090':workstation,'CLZ-100':expressions,'CLZ-110':readiness,
    'CLZ-120':first_deployment,'CLZ-130':authentication,'CLZ-140':tags,
    'CLZ-150':interface,'CLZ-160':state_binding,'CLZ-170':cidr_map,'CLZ-180':nsg_decisions,
}

DESCRIPTIONS = {
    'CLZ-090':'A workstation toolbench connects Git, VS Code, Terraform CLI, and Azure CLI to the PowerShell command surface. A readiness audit checks versions and PATH. All tools remain local in this optional lesson; no Azure connection or deployment occurs.',
    'CLZ-100':'Three harmless inputs, environment dev, prefix clz, and preview region eastus2, flow through Terraform naming and tag expressions into a planned configuration_preview. The planned resource group name is clz-dev-clz100-rg. No provider or Azure object exists; terraform show tfplan reads proposed outputs.',
    'CLZ-110':'Azure CLI reads the selected identity context and compares intended tenant, subscription, region, role scope, and VM quota. Dotted arrows denote metadata inspection. Terraform only emits local readiness commands; no Azure resource is created.',
    'CLZ-120':'A saved Terraform plan proposes one resource group. Deliberate apply creates the tagged Azure group and records its resource address and Azure ID in local state. Read-back verification compares the actual object, and cleanup audits its removal.',
    'CLZ-130':'The signed-in Azure CLI user supplies a tenant-bound access token to AzureRM. A separate subscription GUID selects the target, while a role at the appropriate scope determines authorization. Authentication does not itself grant deployment rights.',
    'CLZ-140':'One named resource group is surrounded by its four ownership and organization tags: Project, Environment, ManagedBy Terraform, and fixed Lab CLZ-140. Tags are metadata; they neither grant permissions nor automatically inherit to child resources.',
    'CLZ-150':'Typed inputs flow to derived local expressions, then to one managed resource group, then to validation-friendly outputs. The fixed lab ID, derived prefix, location, and standard tag map show the distinction between public interface and implementation values.',
    'CLZ-160':'A Terraform process acquires a short-lived local lock before changing local terraform.tfstate. The state maps azurerm_resource_group.lab to the actual resource ID and is compared with Azure during refresh. Remote Azure Storage is not deployed in this lesson.',
    'CLZ-170':'A single VNet with address space 10.40.0.0/16 contains four distinct subnet ranges: web 10.40.1.0/24, app 10.40.2.0/24, data 10.40.3.0/24, and management 10.40.10.0/24. The nested address allocation view is not to scale; no workloads or security appliance are created.',
    'CLZ-180':'Three illustrated inbound requests pass through ordered NSG decisions: priority 100 permits Internet TCP 80, priority 110 permits TCP 3389 from admin_cidr, and priority 120 denies other TCP 3389 sources. The NSG is associated with web-snet; no VM is present. First matching rule wins, and /32 validation checks format rather than public routability.',
}

EXPECTED_RESOURCES = {id:() for id in SCENES}
for id in ('CLZ-120','CLZ-130','CLZ-140','CLZ-150','CLZ-160'):
    EXPECTED_RESOURCES[id] = ('azurerm_resource_group.lab',)
EXPECTED_RESOURCES['CLZ-170'] = ('azurerm_resource_group.lab','azurerm_virtual_network.main','azurerm_subnet.web','azurerm_subnet.app','azurerm_subnet.data','azurerm_subnet.mgmt')
EXPECTED_RESOURCES['CLZ-180'] = (*EXPECTED_RESOURCES['CLZ-170'],'azurerm_network_security_group.web','azurerm_network_security_rule.allow_http','azurerm_network_security_rule.allow_admin_rdp','azurerm_network_security_rule.deny_other_rdp','azurerm_subnet_network_security_group_association.web')

EXPECTED_CONNECTIONS = {
    'CLZ-090':('preferred_shell = var.preferred_shell','value = local.required_commands'),
    'CLZ-100':('prefix = "${var.name_prefix}-${var.environment}-${local.lab_code}"','resource_group_name = "${local.prefix}-rg"','tags = local.tags'),
    'CLZ-110':('"az vm list-usage --location ${var.location} --output table"','"az provider show --namespace Microsoft.Compute --query registrationState --output tsv"'),
    'CLZ-120':('name = "${local.prefix}-rg"','value = azurerm_resource_group.lab.name'),
    'CLZ-130':('subscription_id = var.subscription_id','source = "hashicorp/azurerm"'),
    'CLZ-140':('ManagedBy = "Terraform"','Lab = local.lab_id','lab_id = "CLZ-140"'),
    'CLZ-150':('tags = local.tags','value = azurerm_resource_group.lab.location','prefix = "${var.name_prefix}-${var.environment}-${local.lab_code}"'),
    'CLZ-160':('value = azurerm_resource_group.lab.name','tags = local.tags'),
    'CLZ-170':('address_space = ["10.40.0.0/16"]','address_prefixes = ["10.40.1.0/24"]','address_prefixes = ["10.40.2.0/24"]','address_prefixes = ["10.40.3.0/24"]','address_prefixes = ["10.40.10.0/24"]','virtual_network_name = azurerm_virtual_network.main.name'),
    'CLZ-180':('priority = 100','priority = 110','priority = 120','source_address_prefix = var.admin_cidr','destination_port_range = "3389"','subnet_id = azurerm_subnet.web.id','network_security_group_id = azurerm_network_security_group.web.id'),
}
