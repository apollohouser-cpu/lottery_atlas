"""Reviewed literal SD rule tabs, independent of dated prize/count reports."""
import json
from pathlib import Path
import re
from urllib.parse import urljoin
from lxml import html
from tooling.south_dakota_draw_results import SPECS

SLUGS = (*SPECS, 'powerball-double-play')
CONTRACT = Path(__file__).with_name('south_dakota_schedule_specs.json')
TEAM_CONTRACT = Path(__file__).with_name('south_dakota_team_specs.json')


def text(node):
    for br in node.xpath('.//br'):
        br.tail = '\n' + (br.tail or '')
    return '\n'.join(' '.join(line.split()) for line in node.text_content().splitlines()
                     if line.strip())


def fragment_blocks(raw):
    if not isinstance(raw, str) or not raw.strip() or 'SD_TABLE_TOKEN_' in raw:
        raise ValueError('Invalid schedule fragment')
    tree = html.fragment_fromstring(raw, create_parent='div')
    if tree.xpath('.//script|.//style|.//iframe|.//img'):
        raise ValueError('Unreviewed nontext schedule content')
    tables = []
    for table in tree.xpath('.//table'):
        if table.xpath('.//table'):
            raise ValueError('Nested schedule table')
        rows = []
        for row in table.xpath('.//tr'):
            cells = row.xpath('./th|./td')
            if not cells or any(c.get('rowspan', '1') != '1' or c.get('colspan', '1') != '1' for c in cells):
                raise ValueError('Ambiguous physical table row')
            rows.append([text(c) for c in cells])
        if len(rows) < 2 or not rows[0] or any(len(r) != len(rows[0]) or any(not c for c in r) for r in rows):
            raise ValueError('Incomplete physical schedule')
        token = html.Element('span'); token.text = f'\nSD_TABLE_TOKEN_{len(tables)}\n'
        token.tail = table.tail
        table.getparent().replace(table, token)
        tables.append(dict(kind='table', columns=rows[0], rows=rows[1:]))
    blocks = []
    for part in re.split(r'(SD_TABLE_TOKEN_\d+)', text(tree)):
        part = part.strip()
        if not part:
            continue
        if part.startswith('SD_TABLE_TOKEN_'):
            blocks.append(tables[int(part.rsplit('_', 1)[1])])
        else:
            blocks.append(dict(kind='text', text=part))
    return blocks


def validate_teams(rows):
    if not isinstance(rows, list) or len(rows) != 32:
        raise ValueError('Incomplete source team map')
    mapped = {}
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get('id'), str) or row['id'] in mapped:
            raise ValueError('Invalid or duplicate source team ID')
        mapped[row['id']] = row.get('teamName')
    if mapped != json.loads(TEAM_CONTRACT.read_text()):
        raise ValueError('Changed source team identity mapping')
    return mapped


def extract_tabs(raw, slug):
    if slug not in SLUGS:
        raise ValueError('Unsupported schedule game')
    tree = html.fromstring(raw)
    nodes = tree.xpath('//script[@id="__NEXT_DATA__"]/text()')
    if len(nodes) != 1:
        raise ValueError('Missing or ambiguous page data')
    post = json.loads(nodes[0])['props']['pageProps']['post']
    expected = 'Powerball' if slug == 'powerball-double-play' else SPECS[slug][0]
    if post.get('slug') != slug or post.get('acf', {}).get('igtIdentifier') != expected:
        raise ValueError('Schedule page identity mismatch')
    if slug == 'xs-and-os':
        validate_teams(post['acf'].get('teamLogoMap'))
    matches = [b['attributes']['data']['howtoplay']['howToPlayTabs']
               for b in post['blocks'] if b.get('attributes', {}).get('data', {}).get('howtoplay')]
    if len(matches) != 1 or not matches[0]:
        raise ValueError('Missing or ambiguous rule tabs')
    return matches[0]


def parse_schedules(raw, slug):
    tabs = extract_tabs(raw, slug)
    if tabs != json.loads(CONTRACT.read_text())[slug]:
        raise ValueError('Changed rule/schedule/qualification requires review')
    sections = []
    for tab in tabs:
        blocks, links = [], []
        for layout in tab['layouts']:
            kind = layout['layoutName']
            if kind == 'list':
                fragments = [item['content'] for item in layout['list']]
            elif kind in ('table', 'wysiwyg'):
                fragments = [layout['table' if kind == 'table' else 'content']]
            else:
                raise ValueError('Unreviewed rule layout')
            for raw_fragment in fragments:
                blocks.extend(fragment_blocks(raw_fragment))
                for a in html.fragment_fromstring(raw_fragment, create_parent='div').xpath('.//a[@href]'):
                    url = urljoin('https://lottery.sd.gov/', a.get('href'))
                    if not url.startswith(('https://', 'http://')):
                        raise ValueError('Invalid rule source link')
                    links.append(dict(label=' '.join(a.text_content().split()), url=url))
        sections.append(dict(title=tab['tabTitle'], blocks=blocks, links=links))
    return sections
