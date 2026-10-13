"""Check shipped routes, local links, quiz references, downloads and accessibility."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
from urllib.parse import unquote, urlsplit
from site_common import ROOT, PHASES, catalog, lesson_path


class Page(HTMLParser):
    def __init__(self, content):
        super().__init__()
        self.links, self.ids, self.images = [], set(), []
        self.skip = False
        self.feed(content)

    def handle_starttag(self, tag, attrs):
        data = dict(attrs)
        if data.get('id'): self.ids.add(data['id'])
        for attribute in ('href', 'src'):
            if data.get(attribute): self.links.append(data[attribute])
        if tag == 'img': self.images.append(data)
        if tag == 'a' and data.get('class') == 'md-skip': self.skip = True


def check():
    site = (ROOT/'site').resolve()
    lessons = catalog()
    pages = {path.resolve(): Page(path.read_text(encoding='utf-8')) for path in site.rglob('*.html')}
    errors = []
    for path, page in pages.items():
        assert page.skip or path.name in {'404.html'}, f'Missing skip navigation: {path}'
        for image in page.images:
            assert image.get('alt', '').strip(), f'Missing image alternative text: {path}'
        for link in page.links:
            url = urlsplit(link)
            if url.scheme or url.netloc or link.startswith('/'): continue
            target = (path.parent/unquote(url.path)).resolve() if url.path else path
            if target.is_dir(): target /= 'index.html'
            if not target.is_relative_to(site) or not target.is_file():
                errors.append(f'{path.relative_to(site)} -> {link}')
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
                errors.append(f'{path.relative_to(site)} -> missing #{url.fragment} in {target.relative_to(site)}')
    assert not errors, '\n'.join(errors)
    assert len(list((site/'labs').glob('CLZ-*/index.html'))) == 31
    index = json.loads((site/'assets/quiz/index.json').read_text(encoding='utf-8'))
    assert len(index['labs']) == 30
    count = 0
    for lesson in lessons:
        path = site/lesson_path(lesson)/'index.html'
        assert path.is_file()
        content = path.read_text(encoding='utf-8')
        assert f'data-zth-lesson="{lesson["Id"]}"' in content
        assert f'{lesson["Id"]}-learning.svg' in content
        assert f'{lesson["Id"]}-concept.svg' in content
        assert content.index(f'{lesson["Id"]}-concept.svg') > content.index('id="architecture"'), f'Teaching diagram must be in Architecture: {lesson["Id"]}'
        if lesson['Id'] == 'CLZ-090': continue
        bank = json.loads((site/'assets/quiz'/f'{lesson["Id"]}.json').read_text(encoding='utf-8'))
        assert len(bank['questions']) == 30
        authored = json.loads((ROOT/'assessments'/f'{lesson["Id"]}.json').read_text(encoding='utf-8-sig'))
        for question, original in zip(bank['questions'], authored['questions']):
            assert {key:value for key,value in question.items() if key != 'reviewUrl'} == original, f'Compiled question differs from source: {original["id"]}; rebuild after author edits'
            assert question['reviewUrl'] == lesson_path(lesson)+original['remediationAnchor']
            assert original['remediationAnchor'][1:] in pages[path.resolve()].ids
            count += 1
    assert count == 900
    assert hashlib.sha256((site/'ClickopzBook.pdf').read_bytes()).digest() == hashlib.sha256((ROOT/'ClickopzBook.pdf').read_bytes()).digest()
    assert len(list((site/'assets/diagrams').glob('*.svg'))) == 15
    assert len(list((site/'assets/illustrations').glob('*.svg'))) == 72
    assert len(list((site/'assets/illustrations').glob('CLZ-*-concept.svg'))) == 31
    assert (site/'assets/markers.css').is_file()
    for phase, slug in PHASES.items():
        asset = site/'assets/illustrations'/f'{slug}-scene.png'
        assert asset.is_file() and asset.stat().st_size > 1000, f'Missing original artwork: {phase}'
        for route in ['index.html', f'phases/{slug}/index.html']:
            assert f'{slug}-scene.png' in (site/route).read_text(encoding='utf-8')
    for route in ['index.html', 'learning-pathways/index.html', 'visual-guides/index.html']:
        assert 'curriculum-journey.svg' in (site/route).read_text(encoding='utf-8')
    gallery = (site/'visual-guides/index.html').read_text(encoding='utf-8')
    for visual in list((site/'assets/illustrations').glob('*.svg')) + list((site/'assets/diagrams').glob('*.svg')):
        assert visual.name in gallery, f'Missing gallery visual: {visual.name}'
        original = ROOT/'assets'/visual.parent.name/visual.name
        assert hashlib.sha256(visual.read_bytes()).digest() == hashlib.sha256(original.read_bytes()).digest(), f'Rebuild after visual edits: {visual.name}'
    for raster in list((site/'assets/illustrations').glob('*-scene.png')) + [site/'assets/illustrations/zero-to-hero-cover.png']:
        original = ROOT/'assets/illustrations'/raster.name
        assert hashlib.sha256(raster.read_bytes()).digest() == hashlib.sha256(original.read_bytes()).digest(), f'Staged artwork differs from original: {raster.name}'
    assert not list(site.rglob('terraform.tfvars')) and not list(site.rglob('*.tfstate*'))
    assert not list(site.rglob('tfplan'))
    assert len(list((site/'wiki').glob('*/index.html'))) == 14
    examples = list((site/'downloads/CLZ-370').glob('*.yml.example'))
    assert examples and all(path.suffix == '.example' for path in examples)
    print(f'PASS: {len(pages)} pages, all local links and anchors, 31 lessons, 900 unchanged compiled questions, 87 SVGs, 6 new phase scenes, 14 guides and identical book')


if __name__ == '__main__':
    check()
