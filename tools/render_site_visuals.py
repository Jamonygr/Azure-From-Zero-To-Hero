"""Original deterministic learning illustrations and faithful diagram restyling."""
import argparse
import hashlib
from html import escape
import json
import re
import textwrap
from pathlib import Path
import xml.etree.ElementTree as ET
from site_common import ROOT, PHASES, catalog
from teaching_visuals import teaching_outputs

BLUE, CYAN, PURPLE = "#61caff", "#60e0e5", "#b39bff"
NS = "{http://www.w3.org/2000/svg}"
ICONS = {
    "terminal": '<rect x="8" y="12" width="68" height="54" rx="8"/><path d="m22 28 13 11-13 11m21 0h16"/>',
    "network": '<rect x="29" y="29" width="26" height="26" rx="5"/><path d="M42 29V12m0 43v17M29 42H12m43 0h17"/><circle cx="42" cy="9" r="5"/><circle cx="42" cy="75" r="5"/><circle cx="9" cy="42" r="5"/><circle cx="75" cy="42" r="5"/>',
    "server": '<rect x="18" y="8" width="49" height="68" rx="8"/><path d="M18 29h49M18 52h49m-38-35h2m-2 24h2m-2 23h2m12-47h15M43 41h15M43 64h15"/>',
    "storage": '<ellipse cx="42" cy="17" rx="27" ry="10"/><path d="M15 17v47c0 13 54 13 54 0V17M15 39c0 13 54 13 54 0"/>',
    "shield": '<path d="m42 8 28 12v22c0 16-14 26-28 34C28 68 14 58 14 42V20Z"/><path d="m28 41 10 10 20-23"/>',
    "monitor": '<rect x="8" y="10" width="68" height="49" rx="8"/><path d="M42 59v14m-19 0h38M18 44l13-13 10 8 22-18"/>',
    "plan": '<rect x="19" y="8" width="46" height="68" rx="8"/><path d="M30 25h24M30 38h24M30 51h14m-14 12h24"/>',
    "cloud": '<path d="M24 60h39c25 0 25-34 2-37-8-24-40-22-46 1C-3 30 0 60 24 60Z"/><path d="m30 40 12 12 15-22"/>',
    "trash": '<path d="M19 24h46l-4 51H23Zm-6-8h58M32 16V8h20v8M33 36v24m18-24v24"/>',
    "search": '<circle cx="35" cy="34" r="23"/><path d="m52 52 24 24M23 29h24M23 39h17"/>',
}


def icon(kind, x, y, size=84, color=CYAN):
    return f'<g transform="translate({x} {y}) scale({size / 84})" fill="none" stroke="{color}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round">{ICONS[kind]}</g>'


def text(value, x, y, size=25, color="#eaf2ff", width=42, weight=500):
    lines = textwrap.wrap(value, width=width, break_long_words=False, break_on_hyphens=False)
    return ''.join(f'<text x="{x}" y="{y + n * (size + 8)}" fill="{color}" font-family="Segoe UI, Arial, sans-serif" font-size="{size}" font-weight="{weight}">{escape(line)}</text>' for n, line in enumerate(lines))


def svg(title, description, content, width=700, height=1120, metadata=None):
    meta = f'<metadata>{escape(json.dumps(metadata, sort_keys=True))}</metadata>' if metadata else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc"><title id="title">{escape(title)}</title><desc id="desc">{escape(description)}</desc>{meta}<rect width="{width}" height="{height}" rx="25" fill="#080e1b"/><rect x="14" y="14" width="{width-28}" height="{height-28}" rx="20" fill="none" stroke="#293c5c"/>{content}</svg>\n'


def steps_figure(title, description, steps, footer, metadata=None):
    body = text(title, 35, 57, 31, width=34, weight=750)
    title_lines = len(textwrap.wrap(title, width=34, break_long_words=False, break_on_hyphens=False))
    body += text(description, 35, max(155, 57+(title_lines-1)*39+50), 23, "#b8cbea", width=49)
    for index, (kind, heading, detail) in enumerate(steps):
        y = 260 + index * 210
        color = [CYAN, PURPLE, BLUE][index % 3]
        body += f'<rect x="30" y="{y}" width="640" height="180" rx="19" fill="#111c30" stroke="#293c5c"/>'
        body += f'<circle cx="95" cy="{y+64}" r="49" fill="#12263c" stroke="{color}"/>'
        body += icon(kind, 58, y + 27, 74, color)
        step_heading = f'{index+1:02}  {heading}'
        heading_lines = len(textwrap.wrap(step_heading, width=30, break_long_words=False, break_on_hyphens=False))
        body += text(step_heading, 161, y + 44, 27, width=30, weight=700)
        body += text(detail, 161, y + 44+(heading_lines-1)*35+33, 22, "#bdd0ec", width=40)
        if index < len(steps)-1:
            body += f'<path d="M95 {y+184}v19m-5-5 5 5 5-5" fill="none" stroke="{CYAN}" stroke-width="2"/>'
    height = 260 + len(steps) * 210 + 120
    body += text(footer, 35, height - 85, 22, "#c4d7f4", width=55)
    return svg(title, description + '. Arrows describe learning order, not Azure network traffic.', body, height=height, metadata=metadata)


def lesson_steps(item):
    number = int(item['Id'][4:])
    if number == 90:
        return [('terminal','Inspect the workstation','Read versions and installed tools'),('plan','Review installation choices','Use the contributor setup instructions'),('shield','Verify trusted downloads','Check the pinned versions and hashes'),('terminal','Confirm the toolchain','Run the local readiness audit'),('monitor','Record readiness','Resolve blocking results before labs')]
    if number == 100:
        return [('plan','Read local expressions','No Azure provider or resource exists'),('terminal','Initialize and check','Use backend-free local initialization'),('search','Inspect the saved plan','Read planned outputs from tfplan'),('monitor','Validate the preview','Compare names, location, and tags'),('trash','Remove local artifacts','No Azure destroy is needed')]
    if number == 110:
        return [('terminal','Audit required tools','Use PowerShell 7 and the CLI'),('shield','Choose intended context','Compare tenant and subscription IDs'),('search','Inspect Azure readiness','Read permissions, quota, and region'),('monitor','Interpret each result','Repair a blocking readiness failure'),('plan','Record the context','This lesson makes no Azure changes')]
    if number == 370:
        return [('plan','Read workflow examples','Examples remain inactive downloads'),('shield','Review pins and access','Keep root CI credential-free'),('terminal','Run offline quality checks','Validate with mocked provider data'),('monitor','Review CI evidence','Fix failures before publishing code'),('trash','Keep runtime data local','Never commit plans, state, or secrets')]
    concepts = {
        120: ('cloud','First resource group','Plan, apply, read back, then destroy'),
        130: ('shield','Provider authentication','Match CLI tenant and subscription'),
        140: ('plan','Names and standard tags','Inspect environment and ownership tags'),
        150: ('terminal','Inputs become outputs','Trace variables through local expressions'),
        160: ('storage','State binds real objects','Protect state and respect locking'),
        170: ('network','One VNet, distinct subnets','Compare CIDRs and subnet boundaries'),
        180: ('shield','NSG rules in priority order','HTTP teaching access; scoped RDP source'),
        190: ('server','Windows VM relationships','Connect NIC, disk, image, and credentials'),
        200: ('terminal','Bootstrap IIS with an extension','Verify the script, service, and HTTP page'),
        210: ('shield','Bastion reaches private RDP','Keep workload NICs without public IPs'),
        220: ('network','Two private HTTP backends','Probe health and explicit outbound SNAT'),
        230: ('network','One RDP NAT mapping','50001 reaches 3389 on web[0]'),
        240: ('server','Count creates indexed instances','Inspect addresses and replacement plans'),
        250: ('server','For each uses stable keys','Review a named instance map'),
        260: ('server','Manually size a Windows VMSS','Review capacity and latest instance model'),
        270: ('monitor','CPU rules drive autoscaling','Bound minimum, default, and maximum'),
        280: ('network','NAT Gateway supplies egress','Outbound translation is not inbound RDP'),
        290: ('network','Private DNS needs a VNet link','Resolve records from the linked network'),
        300: ('network','Public DNS remains optional','Owned domain only; checks can warn'),
        310: ('storage','Storage hosts remote state','Migrate state and retain consumer access'),
        320: ('storage','Consume another lesson state','CLZ-310 must exist before this lesson'),
        330: ('network','Traffic Manager returns DNS','Priority routing does not terminate TLS'),
        340: ('shield','Key Vault protects a secret','Review RBAC, network access, and state'),
        350: ('storage','Blob access uses private IPs','Link private DNS; disable public access'),
        360: ('monitor','Provision monitoring foundations','Inspect workspace and empty action group'),
        380: ('storage','SQL through a private endpoint','Verify private DNS and network reachability'),
        390: ('cloud','Combine the reference modules','VMSS, Bastion, vault, and workspace'),
    }
    cleanup = 'Destroy, then verify removal'
    if number == 310:
        cleanup = 'Keep the backend while CLZ-320 uses it'
    if number == 320:
        cleanup = 'Destroy CLZ-320 before its CLZ-310 backend'
    return [concepts[number],('plan','Review inputs and costs',item['CostTier'] + ' relative cost; explicit subscription'),('search','Inspect the saved plan','Review changes; resolve check warnings'),('monitor','Apply and verify deliberately','Follow deployment and read-back commands'),('trash','Follow the cleanup boundary',cleanup)]


def restyle(source):
    """Preserve every original label, shape and connection; add symbolic header icons."""
    tree = ET.fromstring(source.read_text(encoding='utf-8'))
    width, height = map(float, tree.attrib['viewBox'].split()[2:])
    colors = {'#f8fafc':'#080e1b','#f7fafc':'#080e1b','#ffffff':'#101d32','#fff':'#101d32','#111827':'#eff5ff','#374151':'#bcd0eb','#2563eb':BLUE,'#1f6feb':BLUE,'#0f766e':CYAN,'#0284c7':CYAN,'#dbeafe':'#172747','#e0f2fe':'#122b3f','#ffe4e6':'#271b3f','#be123c':PURPLE,'#fef3c7':'#262137','#ca8a04':PURPLE}
    colors.update({'#eef2ff':'#1c2041','#ecfdf5':'#11332f','#ede9fe':'#251d42','#fff7ed':'#30233a','#e5e7eb':'#1c2a3c','#f3e8ff':'#251d42','#ccfbf1':'#11332f','#cffafe':'#12303d','#ecfeff':'#122b3f','#7c3aed':PURPLE,'#9333ea':PURPLE,'#4f46e5':PURPLE,'#059669':CYAN,'#0e7490':CYAN,'#1d4ed8':BLUE,'#ea580c':PURPLE})
    for element in tree.iter():
        for key, value in list(element.attrib.items()):
            if value in colors:
                element.set(key, colors[value])
        if element.tag == NS + 'style' and element.text:
            element.text = re.sub(r'#[a-fA-F0-9]{3,6}\b', lambda m: colors.get(m[0], m[0]), element.text)
            element.text = element.text.replace('Arial,sans-serif', '"Segoe UI",Arial,sans-serif')
        if element.tag == NS + 'text' and element.text == 'Project = Azure From Zero To Hero':
            element.set('style', 'font-size:15px')
        if element.tag == NS + 'text' and element.text == 'random_password':
            element.set('style', 'font-size:20px')
    metadata = ET.Element(NS+'metadata')
    metadata.text = json.dumps({'sourceSha256':hashlib.sha256(source.read_text(encoding='utf-8').encode('utf-8')).hexdigest(),'preserves':'labels, coordinates, resource shapes, and service connections'},sort_keys=True)
    tree.insert(2, metadata)
    # New decorative strip is separate from the original technical drawing.
    tree.set('height', str(int(height+95)))
    tree.set('viewBox', f'0 0 {int(width)} {int(height+95)}')
    strip = ET.fromstring(f'<g xmlns="http://www.w3.org/2000/svg"><rect y="{height}" width="{width}" height="95" fill="#080e1b"/>{icon("cloud",25,height+13,63)}{icon("network",112,height+13,63,PURPLE)}{text("Azure + Terraform learning architecture",210,height+42,23,width=65)}{text("Follow the lesson for exact resource settings and deployment mode.",210,height+70,18,"#bdd0ec",width=100)}</g>')
    tree.append(strip)
    ET.register_namespace('', 'http://www.w3.org/2000/svg')
    return ET.tostring(tree, encoding='unicode')+'\n'


def outputs():
    result = {}
    for source in sorted((ROOT/'assets/diagram-sources').glob('*.svg')):
        result[ROOT/'assets/diagrams'/source.name] = restyle(source)
    phase_icons = ['terminal','plan','network','server','storage','monitor']
    for (phase, slug), kind in zip(PHASES.items(), phase_icons):
        body = f'<circle cx="350" cy="215" r="130" fill="#11243d" stroke="{PURPLE}" stroke-width="2"/>' + icon(kind,240,105,220)
        body += text(phase,50,414,34,width=30,weight=750)
        body += text('Terraform + PowerShell learning pathway',50,455,24,'#bed0ef',width=45)
        result[ROOT/'assets/illustrations'/f'{slug}.svg'] = svg(phase+' learning phase','Original symbolic illustration for the '+phase+' learning phase.',body,height=520)
    for item in catalog():
        readme = ROOT/item['Folder']/'README.md'
        result[ROOT/'assets/illustrations'/f'{item["Id"]}-learning.svg'] = steps_figure(
            item['Id']+' · '+item['Title'],item['DeploymentMode'],lesson_steps(item),
            'Use the lesson commands, permissions, and verification. Progress reports are self-reported.',
            {'lessonId':item['Id'],'sourceSha256':hashlib.sha256(readme.read_text(encoding='utf-8').encode('utf-8')).hexdigest(),'deploymentMode':item['DeploymentMode']},
        )
    shared = {
        'terraform-safe-workflow':('Review before Terraform changes','An explicit plan, deliberate apply, and verified cleanup', [('plan','Set intended inputs','Use an exact subscription ID'),('terminal','Initialize and validate','Check formatting and configuration'),('search','Read the saved plan','Inspect terraform show tfplan'),('cloud','Apply after review','The website never executes this step'),('trash','Destroy and verify','Check Terraform state and Azure')],'check blocks can warn without blocking. Stop and resolve warnings before applying.'),
        'troubleshooting':('Troubleshoot with evidence','Observe the failure, repair its cause, and verify again', [('search','Read the actual error','Identify Terraform or Azure context'),('shield','Inspect prerequisites','Check inputs, access, quota, and region'),('storage','Inspect current state','Compare state with resource read-back'),('terminal','Make a targeted repair','Review a new plan before changes'),('monitor','Repeat verification','Confirm the documented expected result')],'Never delete state or widen public access merely to hide an error.'),
        'state-aware-cleanup':('Clean up in dependency order','Terraform state is the boundary for this course', [('plan','Read the cleanup section','Keep the correct lesson and workspace'),('search','Review managed objects','Use the intended state and subscription'),('trash','Destroy dependent labs first','CLZ-320 must finish before CLZ-310'),('storage','Migrate the backend back','Follow CLZ-310 before removing storage'),('monitor','Audit resources and cost','Verify removal and any retained items')],'Do not delete the remote backend while another lesson still depends on it.'),
    }
    for name, args in shared.items():
        result[ROOT/'assets/illustrations'/f'{name}.svg'] = steps_figure(*args)
    result.update(teaching_outputs())
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    rendered = outputs()
    assert len(rendered) == 87
    for path, value in rendered.items():
        ET.fromstring(value)
        if args.check:
            assert path.is_file() and path.read_text(encoding='utf-8') == value, f'Outdated visual: {path}'
        else:
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text(value,encoding='utf-8',newline='\n')
    print(f'PASS: {len(rendered)} accessible, synchronized SVG visuals')


if __name__ == '__main__':
    main()
