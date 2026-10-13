"""Stage the illustrated site while keeping lesson and Terraform sources authoritative."""
import argparse
from html import escape
import json
import os
import posixpath
import re
import shutil
import struct
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET
from site_common import ROOT, PHASES, catalog, lesson_path
from validate_assessments import validate

OUTPUT = ROOT/'.site-docs'
STATIC = ['terraform-safe-workflow','troubleshooting','state-aware-cleanup']


def write(path, value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(value,encoding='utf-8',newline='\n')


def figure(path, alt, caption, css='zth-teaching-visual'):
    # Dimensions are provided separately by callers for staged relative paths.
    name = Path(path).name
    original = next((p for p in (ROOT/'assets').rglob(name) if 'diagram-sources' not in p.parts),None)
    width, height = (700,1120)
    if original and original.suffix == '.svg':
        width, height = ET.parse(original).getroot().attrib['viewBox'].split()[2:]
    elif original and original.suffix == '.png':
        width,height = struct.unpack('>II', original.read_bytes()[16:24])
    return f'<figure class="{css}"><a href="{path}" aria-label="Open {escape(alt,quote=True)} at full size"><img src="{path}" alt="{escape(alt,quote=True)}" width="{width}" height="{height}" loading="lazy"></a><figcaption>{escape(caption)} <a href="{path}">Open at full size</a>.</figcaption></figure>'


def card(lesson, prefix=''):
    url = prefix+lesson_path(lesson)
    image = prefix+f'assets/illustrations/{lesson["Id"]}-learning.svg'
    optional = ' · Optional' if lesson['Id'] in {'CLZ-090','CLZ-300'} else ''
    quiz = 0 if lesson['Id']=='CLZ-090' else 30
    return f'<article class="zth-lab-card zth-visual-card">{figure(image,lesson["Id"]+" lesson learning sequence","Learning sequence; follow the lesson for commands.","")}<div class="zth-card-body"><span class="zth-eyebrow">{lesson["Id"]}{optional}</span><h3><a href="{url}">{escape(lesson["Title"])}</a></h3><p>{escape(lesson["Phase"])} · {escape(lesson["CostTier"])} relative cost</p><p>{escape(lesson["DeploymentMode"])} · {quiz} questions</p><p>Prerequisites: {escape(', '.join(lesson['Prerequisites']) or 'None')}</p><a class="zth-card-link" href="{url}">Open lesson →</a></div></article>'


def cards(lessons,prefix=''):
    return '<div class="zth-home"><div class="zth-lab-grid">'+''.join(card(item,prefix) for item in lessons)+'</div></div>\n'


def source_paths(lessons):
    paths = subprocess.run(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=ROOT,check=True,capture_output=True).stdout.decode('utf-8').split('\0')
    mapping = {'README.md':'index.md','ClickopzBook.pdf':'ClickopzBook.pdf'}
    for path in paths:
        if path.startswith(('assets/','wiki/','modules/','scripts/')) and not path.startswith('assets/diagram-sources/'):
            mapping[path] = path
        elif path.startswith('CLZ-'):
            if '/.github/workflows/' in path:
                mapping[path] = 'downloads/CLZ-370/'+Path(path).name
            else:
                mapping[path] = 'labs/'+path
        elif '/' not in path and path.endswith('.md') and path != 'README.md':
            mapping[path] = 'repository/'+path
    for item in lessons:
        mapping[item['Folder']+'/README.md'] = lesson_path(item)+'index.md'
    for path in (ROOT/'docs/site').glob('*.md'):
        mapping[path.relative_to(ROOT).as_posix()] = path.name
    return mapping


def rewrite(content, original, target, mapping):
    def link(match):
        before,url,after = match.groups()
        parsed = urlsplit(url.strip('<>'))
        if parsed.scheme or parsed.netloc or not parsed.path:
            return match[0]
        source = posixpath.normpath(posixpath.join(posixpath.dirname(original),unquote(parsed.path)))
        destination = mapping.get(source)
        if not destination:
            if (ROOT/source).is_dir():
                destination = mapping.get(source+'/README.md')
        if not destination:
            raise ValueError(f'Unmapped local link in {original}: {url}')
        relative = posixpath.relpath(destination,posixpath.dirname(target) or '.')
        if parsed.fragment:
            relative += '#'+parsed.fragment
        return before+relative+after
    content = re.sub(r'(!?\[[^\]]*\]\()([^\s)]+)(\))',link,content)
    def alert(match):
        kind = {'CAUTION':'danger','WARNING':'warning','IMPORTANT':'warning','NOTE':'note','TIP':'tip'}[match[1]]
        body = '\n'.join('    '+line.removeprefix('>').lstrip() for line in match[2].splitlines())
        return f'!!! {kind}\n{body}\n'
    return re.sub(r'^> \[!(CAUTION|WARNING|IMPORTANT|NOTE|TIP)\]\n((?:>[^\n]*\n?)+)',alert,content,flags=re.M)


def stage(allow_partial=False):
    lessons = catalog(); banks = validate(allow_partial)
    temp = ROOT/'.site-docs.tmp'
    assert temp.resolve().parent == ROOT.resolve() and OUTPUT.resolve().parent == ROOT.resolve()
    if temp.exists(): shutil.rmtree(temp)
    temp.mkdir()
    mapping = source_paths(lessons)
    safe_suffixes = {'.md','.svg','.png','.pdf','.tf','.hcl','.ps1','.psd1','.json','.txt'}
    for original,target in mapping.items():
        if original in {'README.md'} or not (ROOT/original).is_file(): continue
        if not (Path(original).suffix in safe_suffixes or original.endswith(('.tfvars.example','.yml.example'))): continue
        if Path(original).suffix == '.md':
            content = (ROOT/original).read_text(encoding='utf-8-sig')
            content = rewrite(content,original,target,mapping)
            lesson = next((item for item in lessons if original == item['Folder']+'/README.md'),None)
            if lesson:
                content = re.sub(r'!\[([^\]]+)\]\(([^)]+\.svg)\)',lambda m:figure(m[2],m[1],'Service or workflow illustration. The lesson defines the exact resource settings.'),content,count=1)
                visual = figure(f'../../assets/illustrations/{lesson["Id"]}-learning.svg',lesson['Id']+' learning sequence','Arrows show the learning sequence, not service traffic. '+lesson['DeploymentMode']+'.','zth-teaching-visual zth-learning-visual')
                content = content.replace('\n## Prerequisites\n','\n'+visual+'\n\n## Prerequisites\n',1)
                for heading,name,caption in [('Deploy','terraform-safe-workflow','Review the plan and lesson-specific gates before deliberate execution. Local-only and read-only lessons create no Azure resources.'),('Troubleshooting','troubleshooting','Gather evidence, repair the cause, and rerun verification.'),('Cleanup','state-aware-cleanup','Use the lesson state and cleanup instructions. Preserve remote-state dependencies until consumers are removed.')]:
                    content = content.replace('\n## '+heading+'\n','\n## '+heading+'\n\n'+figure('../../assets/illustrations/'+name+'.svg',caption,caption,'zth-teaching-visual zth-learning-visual')+'\n',1)
                content += f'\n<div data-zth-lesson="{lesson["Id"]}"></div>\n'
            image_prefix = '' if Path(target).name == 'index.md' else '../'
            content = re.sub(r'!\[([^\]]+)\]\(([^)]+\.(?:svg|png))\)',lambda m:figure(image_prefix+m[2],m[1],'Conceptual teaching illustration. Follow the guide for exact configuration.'),content)
            write(temp/target,content)
        else:
            (temp/target).parent.mkdir(parents=True,exist_ok=True); shutil.copy2(ROOT/original,temp/target)
    for source in (ROOT/'docs/site').glob('*.md'):
        # These authors' relative links are expressed relative to their source location.
        content = rewrite(source.read_text(encoding='utf-8'), source.relative_to(ROOT).as_posix(), source.name, mapping)
        content = re.sub(r'!\[([^\]]+)\]\(([^)]+\.png)\)',lambda m:figure('../'+m[2],m[1],'Companion book cover; its existing rights notice applies.'),content)
        write(temp/source.name,content)
    for source in (ROOT/'docs/site-assets').iterdir():
        if source.is_file():
            (temp/'assets').mkdir(exist_ok=True); shutil.copy2(source,temp/'assets'/source.name)
    infos = [{'labId':item['Id'],'title':item['Title'],'pathUrl':lesson_path(item),'questionCount':0 if item['Id']=='CLZ-090' else 30,'bankUrl':item['Id']+'.json'} for item in lessons]
    write(temp/'assets/catalog.json',json.dumps({'schemaVersion':'1.0.0','labs':infos},indent=2))
    quiz_infos = [item for item in infos if item['questionCount']]
    write(temp/'assets/quiz/index.json',json.dumps({'schemaVersion':'1.0.0','labs':quiz_infos},indent=2))
    for lesson,bank in banks:
        questions = [dict(item,reviewUrl=lesson_path(lesson)+item['remediationAnchor']) for item in bank['questions']]
        write(temp/'assets/quiz'/f'{lesson["Id"]}.json',json.dumps({'schemaVersion':'1.0.0','labId':lesson['Id'],'pathUrl':lesson_path(lesson),'questions':questions},ensure_ascii=False,indent=2))
    write(temp/'index.md',homepage(lessons))
    write(temp/'labs/index.md','# Lesson catalog\n\n30 main lessons and an optional contributor setup. CLZ-300 public DNS is optional. Costs and deployment modes come directly from the curriculum.\n\n'+cards(lessons,'../'))
    pathway = '# Learning pathways\n\nBegin with CLZ-100. Use CLZ-090 when your local toolchain needs setup. Read-only readiness in CLZ-110 precedes the first deployment in CLZ-120.\n\n'
    for phase,slug in PHASES.items():
        items = [item for item in lessons if item['Phase']==phase]
        pathway += f'## {phase}\n\n[Explore this phase](phases/{slug}.md) · '+', '.join(item['Id'] for item in items)+'\n\n'
        write(temp/f'phases/{slug}.md',f'# {phase}\n\n'+figure(f'../../assets/illustrations/{slug}.svg',phase+' learning phase','Conceptual phase illustration.')+'\n\n'+cards(items,'../../'))
    pathway += '## Keep the state dependency safe\n\nCLZ-320 consumes state hosted by CLZ-310. Destroy CLZ-320 first, migrate CLZ-310 back to local state as documented, then remove the backend. [Read the state exercise](labs/CLZ-310-remote-state-storage/index.md).\n'
    write(temp/'learning-pathways.md',pathway)
    gallery = '# Visual guides\n\nExplore the original illustrated guides. Learning arrows show exercise order; service diagrams show conceptual connections. Open each illustration for readable full-size labels.\n\n## Terraform habits\n\n'
    for name in STATIC:
        gallery += figure(f'../assets/illustrations/{name}.svg',name.replace('-',' '),'Follow the exact lesson instructions.','zth-teaching-visual zth-learning-visual')+'\n\n'
    gallery += '## Every lesson\n\n'+cards(lessons,'../')
    gallery += '\n## Architecture library\n\n'
    for source in sorted((ROOT/'assets/diagrams').glob('*.svg')):
        title = ET.parse(source).getroot().find('{http://www.w3.org/2000/svg}title').text
        gallery += figure('../assets/diagrams/'+source.name,title,'Original diagram labels and service connections are preserved.')+'\n\n'
    write(temp/'visual-guides.md',gallery)
    if OUTPUT.exists(): shutil.rmtree(OUTPUT)
    temp.rename(OUTPUT)
    print(f'PASS: staged 31 lessons, 14 wiki guides, book and {len(banks)} quiz banks at {OUTPUT}')


def homepage(lessons):
    cover = figure('assets/illustrations/zero-to-hero-cover.png','Azure From Zero To Hero illustrated cover','Original conceptual cover art; use the lessons for technical topology.','zth-cover')
    hero = '<div class="zth-hero"><span class="zth-eyebrow">TERRAFORM + POWERSHELL · WINDOWS FIRST</span><h2>Build practical <span>Azure skills.</span></h2><p>Start with Terraform fundamentals, then build, secure, automate, and operate a Windows-based Azure platform.</p><div class="zth-hero-actions"><a class="zth-button zth-button-primary" href="labs/CLZ-100-foundations/">Start learning →</a><a class="zth-button zth-button-secondary" href="practice/">Practice questions</a><a class="zth-button zth-button-secondary" href="ClickopzBook.pdf">Download the book</a></div></div>'
    stats = '<div class="zth-stats">'+''.join(f'<div class="zth-stat"><strong>{value}</strong><span>{label}</span></div>' for value,label in [('30 + 1','labs and optional setup'),('900','original practice questions'),('6','learning phases'),('14','reference guides')])+'</div>'
    phases = '<div class="zth-domain-grid">'
    for phase,slug in PHASES.items():
        items = [item for item in lessons if item['Phase']==phase]
        phases += f'<article class="zth-domain-card">{figure("assets/illustrations/"+slug+".svg",phase+" learning phase","Conceptual phase illustration.","")}<div class="zth-card-body"><h3><a href="phases/{slug}/">{phase}</a></h3><p>{len(items)} {"lesson" if len(items)==1 else "lessons"} · {items[0]["Id"]}–{items[-1]["Id"]}</p><a class="zth-card-link" href="phases/{slug}/">Explore the phase →</a></div></article>'
    phases += '</div>'
    return '# Azure From Zero To Hero\n\n<div class="zth-home">'+cover+hero+stats+'</div>\n\n## Choose your learning phase\n\n<div class="zth-home">'+phases+'</div>\n\n## Run safely\n\nAzure resources can be billable. The website never runs Terraform or creates resources. Review your exact subscription, inputs, costs, and saved plan. [Read cost and cleanup guidance](wiki/cost-governance-and-lab-safety.md). Exercise completion in the progress tools is self-reported.\n\n## Curriculum\n\n'+cards(lessons)+'\n## Beyond Clickopz\n\n[Download the free companion book](ClickopzBook.pdf) · [Book rights and errata](companion-book.md) · [Download lab sources (GitHub ZIP)](https://github.com/Jamonygr/Azure-From-Zero-To-Hero/archive/refs/heads/main.zip)\n\nThe book retains its existing all rights reserved notice. No book or repository license is changed.\n\n[Explore visual guides](visual-guides.md) · [Choose a learning pathway](learning-pathways.md) · [View your progress](learner-progress.md)\n'


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--allow-partial',action='store_true',help='Local authoring preview only; never use for CI or publication.')
    stage(parser.parse_args().allow_partial)
