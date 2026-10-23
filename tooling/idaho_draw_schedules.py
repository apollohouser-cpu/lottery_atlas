"""Literal reviewed Idaho schedule tables; broader game rules are separate."""
import copy
import json
from pathlib import Path
from lxml import html

SPECS = json.loads(Path(__file__).with_name('idaho_draw_schedule_specs.json').read_text())


def _text(node):
    return ' '.join(node.text_content().split())


def _extract(raw):
    doc = html.fromstring(raw)
    tables = doc.xpath('//table[contains(concat(" ", normalize-space(@class), " "), " horizontal-prize-matrix ")]')
    titles = doc.xpath('//head/title')
    if len(tables) != 1 or len(titles) != 1:
        raise ValueError('Expected one game title and schedule')
    table = tables[0]
    rows = []
    for row in table.xpath('.//tbody/tr'):
        cells = row.xpath('./td')
        rows.append({'match': row.get('data-number'),
                     'cells': [_text(cell) for cell in cells],
                     'symbols': [li.get('class') for li in row.xpath('./td[1]//li')]})
    return {'title': _text(titles[0]),
            'headers': [_text(cell) for cell in table.xpath('.//thead//th')],
            'rows': rows,
            'containerText': _text(table.getparent())}


def parse_schedule(raw, slug):
    if slug not in SPECS:
        raise ValueError('Unsupported Idaho schedule')
    actual = _extract(raw)
    expected = SPECS[slug]
    if actual != expected:
        raise ValueError('Changed or incomplete Idaho schedule requires review')
    return copy.deepcopy(expected)
