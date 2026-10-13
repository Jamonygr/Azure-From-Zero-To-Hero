"""Validate the original authored bank and every lesson remediation reference."""
import argparse
from collections import Counter
import json
import re
from urllib.parse import urlparse
from jsonschema import Draft202012Validator, FormatChecker
from site_common import ROOT, catalog


def validate(allow_partial=False):
    schema = json.loads((ROOT/'assessments/question-bank.schema.json').read_text(encoding='utf-8'))
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    lessons = catalog()
    if not allow_partial:
        expected = {lesson['Id']+'.json' for lesson in lessons if lesson['Id'] != 'CLZ-090'}
        assert {path.name for path in (ROOT/'assessments').glob('CLZ-*.json')} == expected, 'Unexpected or missing assessment bank'
    stems, ids, count, banks = set(), set(), 0, []
    for lesson in lessons:
        if lesson['Id'] == 'CLZ-090':
            continue
        path = ROOT/'assessments'/f'{lesson["Id"]}.json'
        if allow_partial and not path.is_file():
            continue
        bank = json.loads(path.read_text(encoding='utf-8-sig'))
        validator.validate(bank)
        assert bank['lessonId'] == lesson['Id'], path
        source = (ROOT/lesson['Folder']/'README.md').read_text(encoding='utf-8')
        anchors = {'#'+re.sub(r'[^a-z0-9 -]','',heading.lower()).replace(' ','-') for heading in re.findall(r'^## (.+)$',source,re.M)}
        answers = Counter()
        for index, question in enumerate(bank['questions'],1):
            assert question['id'] == lesson['Id'].replace('-','')+f'-Q{index:02}', question['id']
            stem = re.sub(r'\s+',' ',question['stem'].strip().casefold())
            assert stem not in stems and question['id'] not in ids, f'Duplicate question: {question["id"]}'
            assert question['remediationAnchor'] in anchors, question['id']
            assert len(set(question['options'].values())) == 4, question['id']
            for reference in question['sources']:
                url = urlparse(reference['url'])
                assert url.scheme == 'https' and url.hostname in {'learn.microsoft.com','developer.hashicorp.com'} and not url.username and not url.password
            answers[question['correctOption']] += 1
            stems.add(stem); ids.add(question['id']); count += 1
        assert all(7 <= answers[letter] <= 8 for letter in 'ABCD'), (lesson['Id'],answers)
        banks.append((lesson,bank))
    if not allow_partial:
        assert count == 900 and len(banks) == 30, (count,len(banks))
    print(f'PASS: {len(banks)} schema-valid banks, {count} original unique questions, balanced answers, official sources and lesson anchors')
    return banks


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--allow-partial',action='store_true')
    validate(parser.parse_args().allow_partial)
