"""Reviewed static Iowa qualifications and combinations; source changes fail closed."""
import json
from pathlib import Path
from lxml import html

SPEC_PATH = Path(__file__).with_name('iowa_html_schedule_specs.json')
PAGES = {
    'millionaire_for_life': 'MillionaireForLife',
    'pick3': 'Pick3WinningCombinations',
    'pick4': 'Pick4WinningCombinations',
    'powerball': 'Powerball',
    'mega_millions': 'MegaMillions',
    'lotto_america': 'LottoAmerica',
    'xsos': 'PowerballXsOs',
    'pick3_rules': 'Pick3',
    'pick4_rules': 'Pick4',
}


def _text(element):
    return ' '.join(' '.join(element.itertext()).split())


def extract_sections(raw):
    if isinstance(raw, bytes):
        raw = raw.decode('utf-8-sig')
    document = html.fromstring(raw)
    containers = document.xpath('//div[contains(concat(" ", normalize-space(@class), " "), " primary-content ")]')
    if len(containers) != 1:
        raise ValueError('Ambiguous Iowa primary content')
    sections = []
    elements = []
    for element in containers[0]:
        if element.tag == 'div' and element.get('id'):
            if element.get('id') not in {
                'ContentPlaceHolder1_newTextPBDP',
                'ContentPlaceHolder1_AddDoublePlay',
                'ContentPlaceHolder1_newMatrixApril5',
            }:
                raise ValueError('Unknown Iowa rule section')
            elements.extend(element)
        else:
            elements.append(element)
    for element in elements:
        if element.tag in ('h2', 'h3', 'p'):
            text = _text(element)
            if text:
                sections.append({'kind': element.tag, 'text': text})
        elif element.tag in ('ul', 'ol'):
            sections.append({'kind': element.tag, 'items': [_text(li) for li in element.xpath('./li')]})
        elif element.tag == 'table':
            rows = [[_text(cell) for cell in row.xpath('./th|./td')]
                    for row in element.xpath('./tr|./tbody/tr|./thead/tr')]
            if not rows or any(not row for row in rows):
                raise ValueError('Empty schedule table')
            sections.append({'kind': 'table', 'id': element.get('id'), 'rows': rows})
    if not sections:
        raise ValueError('Missing Iowa schedule sections')
    return sections


def verified_html_schedule(game, raw):
    if game not in PAGES:
        raise ValueError('Unsupported HTML schedule')
    spec = json.loads(SPEC_PATH.read_text())[game]
    sections = extract_sections(raw)
    if sections != spec['sections']:
        raise ValueError('Iowa HTML schedule changed; review required')
    return {'game': game, 'sourceUrl': spec['sourceUrl'], 'sections': sections}
