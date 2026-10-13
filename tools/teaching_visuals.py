"""Original pictorial teaching scenes synchronized with curriculum and Terraform.

Scenes explain a lesson's mechanism. Dashed elements are illustrative or absent
from its deployment; topology assertions and source hashes keep that distinction
reviewable. Rendering is local and never initializes or applies Terraform.
"""
from __future__ import annotations

import hashlib
from html import escape
import json
import math
from pathlib import Path
import re
import textwrap

from site_common import ROOT, PHASES, catalog

BLUE, CYAN, PURPLE = '#61caff', '#60e0e5', '#b39bff'
TEXT, MUTED = '#edf4ff', '#bdd0ec'

# All paths are original line drawings on an 84-unit canvas.
ICONS = {
    'terminal': '<rect x="6" y="12" width="72" height="56" rx="8"/><path d="m20 29 13 11-13 11m24 0h17"/>',
    'plan': '<path d="M19 7h34l13 13v56H19Zm34 0v14h13M29 33h26M29 46h26M29 59h17"/>',
    'cloud': '<path d="M21 63h43c24 0 24-34 2-38C57 0 25 5 20 28-2 32 0 63 21 63Z"/><path d="M31 43h23m-11-11v23"/>',
    'network': '<rect x="30" y="29" width="24" height="25" rx="5"/><path d="M42 29V14m0 40v17M30 42H14m40 0h16"/><circle cx="42" cy="9" r="5"/><circle cx="42" cy="76" r="5"/><circle cx="8" cy="42" r="5"/><circle cx="76" cy="42" r="5"/>',
    'shield': '<path d="m42 7 28 12v23c0 17-14 28-28 35C28 70 14 59 14 42V19Z"/><path d="m27 41 11 11 20-25"/>',
    'server': '<rect x="17" y="7" width="50" height="70" rx="8"/><path d="M17 30h50M17 53h50m-37-35h2m-2 24h2m-2 23h2m12-47h15M44 42h15M44 65h15"/>',
    'storage': '<ellipse cx="42" cy="17" rx="28" ry="10"/><path d="M14 17v47c0 14 56 14 56 0V17M14 39c0 14 56 14 56 0"/>',
    'monitor': '<rect x="6" y="9" width="72" height="50" rx="7"/><path d="M42 59v15M24 74h36M17 44l13-15 13 9 24-20"/>',
    'trash': '<path d="M19 25h46l-4 51H23Zm-6-9h58M32 16V8h20v8M33 36v24m18-24v24"/>',
    'search': '<circle cx="35" cy="34" r="24"/><path d="m52 52 23 23M23 29h24M23 40h16"/>',
    'key': '<circle cx="27" cy="28" r="18"/><path d="m40 41 32 32m-14-14 8-8m-18 4 8-8"/>',
    'git': '<path d="m42 5 37 37-37 37L5 42Z"/><path d="M27 27h18v29m0-18 14 14"/><circle cx="27" cy="27" r="4"/><circle cx="45" cy="56" r="4"/><circle cx="59" cy="52" r="4"/>',
    'windows': '<path d="m8 16 29-4v27H8Zm34-5 34-5v33H42ZM8 44h29v27L8 67Zm34 0h34v34l-34-6Z"/>',
    'dns': '<circle cx="42" cy="42" r="32"/><ellipse cx="42" cy="42" rx="14" ry="32"/><path d="M10 42h64M17 24h50M17 60h50"/>',
    'vault': '<rect x="10" y="9" width="64" height="66" rx="9"/><path d="M16 20v43m0-25h5m-5 14h5"/><circle cx="47" cy="42" r="18"/><path d="M47 30v24M35 42h24m-20-8 16 16m0-16L39 50"/>',
    'sql': '<ellipse cx="42" cy="15" rx="27" ry="9"/><path d="M15 15v51c0 13 54 13 54 0V15M15 32c0 13 54 13 54 0"/><path d="m30 49-8 7 8 7m24-14 8 7-8 7m-14 1 4-17"/>',
    'loadbalancer': '<path d="M10 42h20m24 0h20M42 30V12m0 42v18"/><circle cx="42" cy="42" r="13"/><path d="m20 34 8 8-8 8M34 20l8-8 8 8m-16 43 8 8 8-8m14-37 8 8-8 8"/>',
    'bastion': '<path d="M14 75V28h56v47M9 28V9h12v10h14V9h14v10h14V9h12v19M33 75V54a9 9 0 0 1 18 0v21"/><path d="M25 35v7m34-7v7"/>',
    'tf': '<path d="m8 11 25 14v28L8 39Zm31 17 25 14v28L39 56Zm0-25 25 14v19L39 22Zm31 13 10-6v28l-10 6"/>',
    'cost': '<circle cx="42" cy="42" r="32"/><path d="M53 27H35a9 9 0 0 0 0 18h14a9 9 0 0 1 0 18H30m12-44v49"/>',
    'user': '<circle cx="42" cy="23" r="14"/><path d="M14 74V61c0-24 56-24 56 0v13Z"/>',
    'folder': '<path d="M8 23V13h26l10 10h32v47H8Zm0 10h68"/>',
    'lock': '<rect x="16" y="35" width="52" height="42" rx="8"/><path d="M26 35V23c0-22 32-22 32 0v12M42 51v12"/>',
    'tag': '<path d="M10 11h29l35 35-28 28-36-36Z"/><circle cx="26" cy="26" r="5"/><path d="m40 41 13 13"/>',
    'check': '<circle cx="42" cy="42" r="31"/><path d="m25 42 12 13 24-28"/>',
    'arrow': '<path d="M10 42h64M53 21l21 21-21 21"/>',
}


class Drawing:
    """Layered original vector scene; x/y identify the node's top-left corner."""

    def __init__(self, width=1200, height=800):
        self.width, self.height = width, height
        self.nodes = {}
        self.groups, self.paths, self.boxes, self.labels = [], [], [], []
        self.connections = []
        self._notes = []

    def _text(self, value, x, y, size=24, color=MUTED, width=60, weight=500, anchor='start'):
        assert anchor in {'start', 'middle', 'end'}
        lines = []
        for paragraph in str(value).split('\n'):
            lines.extend(textwrap.wrap(paragraph, width=max(1, int(width)), break_long_words=False, break_on_hyphens=False) or [''])
        return ''.join(f'<text x="{x:g}" y="{y+n*(size+5):g}" fill="{color}" font-family="Segoe UI, Arial, sans-serif" font-size="{size:g}" font-weight="{weight}" text-anchor="{anchor}">{escape(line)}</text>' for n, line in enumerate(lines))

    def text(self, value, x, y, size=24, color=MUTED, width=60, weight=500, anchor='start'):
        self.labels.append(self._text(value, x, y, size, color, width, weight, anchor))

    def _icon(self, kind, x, y, size=84, color=CYAN):
        assert kind in ICONS, f'Unknown icon: {kind}'
        return f'<g transform="translate({x:g} {y:g}) scale({size/84:g})" fill="none" stroke="{color}" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round">{ICONS[kind]}</g>'

    def icon(self, kind, x, y, size=84, color=CYAN):
        self.labels.append(self._icon(kind, x, y, size, color))

    def node(self, id, label, kind, x, y, w=190, h=150, detail=''):
        assert id not in self.nodes, f'Duplicate node: {id}'
        assert 0 <= x <= self.width-w and 140 <= y <= 650-h, f'Node outside scene body: {id}'
        self.nodes[id] = (x, y, w, h)
        color = (CYAN, PURPLE, BLUE)[len(self.nodes) % 3]
        label_size, detail_size = 21, 17
        label_width = max(8, int((w-26)/(label_size*0.56)))
        labels = [line for paragraph in label.split('\n') for line in textwrap.wrap(paragraph, width=label_width, break_long_words=False, break_on_hyphens=False)]
        details = [line for paragraph in detail.split('\n') for line in textwrap.wrap(paragraph, width=max(8, int((w-24)/(detail_size*0.56))), break_long_words=False, break_on_hyphens=False)]
        assert len(labels) <= 3 and len(details) <= 3, f'Too much node text: {id}'
        label_y = y+83
        detail_y = label_y + max(0,len(labels)-1)*26 + 25
        bottom = detail_y + max(0,len(details)-1)*22 if details else label_y + max(0,len(labels)-1)*26
        assert bottom <= y+h-6, f'Increase node size or shorten text: {id}'
        body = f'<g data-node="{escape(id,quote=True)}"><rect x="{x+5:g}" y="{y+7:g}" width="{w:g}" height="{h:g}" rx="18" fill="#030711"/><rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" rx="18" fill="url(#nodeFill)" stroke="{color}" stroke-width="1.7"/><path d="M{x+19:g} {y+1:g}H{x+w-19:g}" stroke="{color}" stroke-width="2.6" opacity="0.7"/>'
        body += self._icon(kind, x+(w-58)/2, y+13, 58, color)
        body += self._text(label, x+w/2, label_y, label_size, TEXT, label_width, 700, 'middle')
        if detail:
            body += self._text(detail, x+w/2, detail_y, detail_size, MUTED, max(8,int((w-24)/(detail_size*0.56))), 500, 'middle')
        self.boxes.append(body+'</g>')

    def group(self, title, x, y, w, h):
        assert 0 <= x and x+w <= self.width and 140 <= y and y+h <= 650
        self.groups.append(f'<g><rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" rx="24" fill="#0d182a" fill-opacity="0.85" stroke="#344968" stroke-width="1.5"/>{self._text(title,x+18,y+30,21,TEXT,max(10,int((w-36)/12)),700)}</g>')

    @staticmethod
    def _boundary(rect, toward):
        x,y,w,h = rect
        cx,cy = x+w/2,y+h/2
        dx,dy = toward[0]-cx,toward[1]-cy
        if not dx and not dy:
            return (cx,cy)
        scale = min(w/(2*abs(dx)) if dx else math.inf, h/(2*abs(dy)) if dy else math.inf)
        return (cx+dx*scale,cy+dy*scale)

    def edge(self, source_id, target_id, label='', style='solid', points=None, label_pos=None):
        source,target = self.nodes[source_id],self.nodes[target_id]
        middle = list(points or [])
        center_s = (source[0]+source[2]/2,source[1]+source[3]/2)
        center_t = (target[0]+target[2]/2,target[1]+target[3]/2)
        path = [self._boundary(source,middle[0] if middle else center_t),*middle,self._boundary(target,middle[-1] if middle else center_s)]
        self.connections.append({'from':source_id,'to':target_id,'label':label,'style':style})
        self.line(path,label,label_pos,style)

    def line(self, points, label='', label_pos=None, style='solid'):
        assert style in {'solid','dashed','dotted'}, f'Unknown edge style: {style}'
        assert len(points) >= 2
        assert all(0 <= p[0] <= self.width and 140 <= p[1] <= 650 for p in points), 'Edge outside body'
        color = {'solid':CYAN,'dashed':PURPLE,'dotted':BLUE}[style]
        dash = {'solid':'','dashed':' stroke-dasharray="10 7"','dotted':' stroke-dasharray="2 8"'}[style]
        d = 'M'+' L'.join(f'{x:g} {y:g}' for x,y in points)
        self.paths.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="3" stroke-linejoin="round"{dash} marker-end="url(#{style}Arrow)"/>')
        if label:
            x,y = label_pos or ((points[0][0]+points[-1][0])/2,(points[0][1]+points[-1][1])/2-11)
            lines = textwrap.wrap(label,width=25,break_long_words=False,break_on_hyphens=False)
            label_w = max(len(t) for t in lines)*10.5+20
            self.paths.append(f'<rect x="{x-label_w/2:g}" y="{y-19:g}" width="{label_w:g}" height="{len(lines)*24:g}" rx="7" fill="#080e1b"/>'+self._text(label,x,y,19,color,25,600,'middle'))

    def note(self, value, x=40, y=710, width=90):
        lines = textwrap.wrap(value,width=int(width),break_long_words=False,break_on_hyphens=False)
        assert y+max(0,len(lines)-1)*25 <= self.height-27, 'Note outside footer'
        self._notes.append(self._text(value,x,y,20,MUTED,width,500))

    def render(self, title, description, metadata=None):
        heading = self._text(title,40,59,31,TEXT,66,750)
        legend = self._text('Solid: shown relationship   ·   Dashed: illustrative / not deployed   ·   Dotted: lookup or inspection',40,675,17,MUTED,115)
        defs = '<defs><linearGradient id="nodeFill" x2="0" y2="1"><stop stop-color="#172a44"/><stop offset="1" stop-color="#101b30"/></linearGradient><pattern id="grid" width="36" height="36" patternUnits="userSpaceOnUse"><path d="M36 0H0V36" fill="none" stroke="#17243a" stroke-width="0.7"/></pattern>'
        for style,color in [('solid',CYAN),('dashed',PURPLE),('dotted',BLUE)]:
            defs += f'<marker id="{style}Arrow" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto" markerUnits="userSpaceOnUse"><path d="m1 1 7 3.5-7 3.5" fill="none" stroke="{color}" stroke-width="2"/></marker>'
        defs += '</defs>'
        data = dict(metadata or {})
        data['visualConnections'] = self.connections
        meta = '<metadata>'+escape(json.dumps(data,sort_keys=True))+'</metadata>'
        content = '<rect width="1200" height="800" rx="25" fill="#080e1b"/><rect x="18" y="18" width="1164" height="764" rx="22" fill="none" stroke="#293c5c"/><rect x="24" y="145" width="1152" height="500" fill="url(#grid)" opacity="0.5"/><path d="M40 123H1160M40 650H1160" stroke="#293c5c"/>'
        content += heading+''.join(self.groups+self.paths+self.boxes+self.labels)+legend+''.join(self._notes)
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" height="{self.height}" viewBox="0 0 {self.width} {self.height}" role="img" aria-labelledby="title desc"><title id="title">{escape(title)}</title><desc id="desc">{escape(description)}</desc>{meta}{defs}{content}</svg>\n'


def normalized_source(path):
    return path.read_text(encoding='utf-8-sig').replace('\r\n','\n').replace('\r','\n')


def source_files(item):
    """Hash lesson sources and recursively resolve only repository-local modules."""
    folder = ROOT/item['Folder']
    paths = {folder/'README.md'}
    pending = list(folder.glob('*.tf'))
    visited = set()
    while pending:
        path = pending.pop()
        if path in visited:
            continue
        visited.add(path)
        paths.add(path)
        for reference in re.findall(r'\bsource\s*=\s*"(\.{1,2}/[^"\n]+)"',normalized_source(path)):
            target = (path.parent/reference).resolve()
            assert target.is_relative_to(ROOT.resolve()), f'Module outside repository: {target}'
            assert target.is_dir(), f'Missing local module: {target}'
            pending.extend(target.glob('*.tf'))
    return sorted(paths,key=lambda p:p.relative_to(ROOT).as_posix())


def source_metadata(item, resources, connections):
    files = source_files(item)
    fingerprints = {p.relative_to(ROOT).as_posix():hashlib.sha256(normalized_source(p).encode('utf-8')).hexdigest() for p in files}
    terraform = '\n'.join(normalized_source(p) for p in files if p.suffix=='.tf')
    declared = {f'{kind}.{name}' for kind,name in re.findall(r'^\s*resource\s+"([^"]+)"\s+"([^"]+)"',terraform,re.M)}
    declared.update(f'data.{kind}.{name}' for kind,name in re.findall(r'^\s*data\s+"([^"]+)"\s+"([^"]+)"',terraform,re.M))
    declared.update(f'module.{name}' for name in re.findall(r'^\s*module\s+"([^"]+)"',terraform,re.M))
    assert set(resources) <= declared, f'{item["Id"]}: illustrated resource absent from Terraform: {set(resources)-declared}'
    if item['Id'] in {'CLZ-090','CLZ-100','CLZ-110'}:
        assert not re.search(r'^\s*(resource|data|provider)\s+"',terraform,re.M), f'Local/read-only lesson changed deployment boundary: {item["Id"]}'
    compact = re.sub(r'\s+','',terraform)
    for token in connections:
        assert re.sub(r'\s+','',token) in compact, f'{item["Id"]}: illustrated connection no longer exists: {token}'
    return {'lessonId':item['Id'],'deploymentMode':item['DeploymentMode'],'sourceFiles':list(fingerprints),'sourceFingerprints':fingerprints,'sourceSha256':hashlib.sha256(json.dumps(fingerprints,sort_keys=True).encode()).hexdigest(),'resourceInventory':sorted(resources),'connectionInventory':list(connections),'sourceValidation':'Curated resource addresses and connection expressions, with source fingerprints; no live Azure test.'}


def journey(lessons):
    draw = Drawing()
    phase_groups = [(phase,[i for i in lessons if i['Phase']==phase]) for phase in PHASES]
    kinds = ['terminal','tf','network','windows','vault','monitor']
    labels = ['Workstation','Foundations','Networking','Windows compute','Platform services','Operations']
    for index,((phase,items),kind,label) in enumerate(zip(phase_groups,kinds,labels)):
        col,row = index%3,index//3
        x,y = 80+col*380,185+row*230
        detail = f'{len(items)} lesson'+('s' if len(items)!=1 else '')+f' · {items[0]["Id"][4:]}–{items[-1]["Id"][4:]}'
        draw.node(str(index),label,kind,x,y,280,155,detail)
    draw.edge('0','1','optional setup',style='dashed',label_pos=(410,173))
    draw.edge('1','2','learn',style='dashed')
    draw.edge('2','3',style='dashed',points=[(1130,365),(60,365)],label='continue below',label_pos=(600,383))
    draw.edge('3','4','build',style='dashed')
    draw.edge('4','5','operate',style='dashed')
    draw.note('Learning order, not network traffic. CLZ-090 setup and CLZ-300 public DNS remain optional.\nCLZ-310/320 share a backend dependency: destroy the consumer before migrating and removing storage.',width=102)
    return draw.render('Your Azure + Terraform learning journey','Six curriculum phases form a learning sequence: optional workstation setup, foundations, networking, Windows compute, platform services, and operations. Dashed arrows indicate learning order rather than Azure network connections. CLZ-300 is optional; CLZ-320 depends on the CLZ-310 remote backend.',{'visualType':'conceptual curriculum journey','catalogSource':'curriculum/lessons.psd1','lessonIds':[i['Id'] for i in lessons],'optionalLessons':['CLZ-090','CLZ-300']})


def teaching_outputs():
    import teaching_foundations
    import teaching_compute
    import teaching_platform
    modules = (teaching_foundations,teaching_compute,teaching_platform)
    scenes, descriptions, resources, connections = {},{},{},{}
    for module in modules:
        assert not set(scenes)&set(module.SCENES), 'Duplicate lesson scene'
        scenes.update(module.SCENES)
        descriptions.update(module.DESCRIPTIONS)
        resources.update(module.EXPECTED_RESOURCES)
        connections.update(module.EXPECTED_CONNECTIONS)
    lessons = catalog()
    ids = {i['Id'] for i in lessons}
    assert set(scenes)==set(descriptions)==set(resources)==set(connections)==ids, 'Teaching scene coverage must match all 31 authoritative lessons'
    result = {}
    for item in lessons:
        lesson_id = item['Id']
        draw = Drawing()
        scenes[lesson_id](draw,item)
        assert draw.nodes, f'Empty scene: {lesson_id}'
        metadata = source_metadata(item,resources[lesson_id],connections[lesson_id])
        result[ROOT/'assets/illustrations'/f'{lesson_id}-concept.svg'] = draw.render(lesson_id+' · '+item['Title'],descriptions[lesson_id],metadata)
    result[ROOT/'assets/illustrations/curriculum-journey.svg'] = journey(lessons)
    assert len(result)==32
    return result
