"""Reviewed InstaPlay schedules, never remaining-prize inventories."""
import json
from pathlib import Path
from lxml import html

SPECS = json.loads(Path(__file__).with_name('idaho_instaplay_specs.json').read_text())


def _text(n):
    return ' '.join(n.text_content().split())


def _extract(raw):
    doc = html.fromstring(raw)
    titles = doc.xpath('//head/title')
    rules = doc.xpath('//*[@id="tab2"]')
    odds = doc.xpath('//*[@id="tab3"]')
    tables = doc.xpath('//table')
    if any(len(nodes) != 1 for nodes in [titles, rules, odds, tables]):
        raise ValueError('Incomplete or duplicate InstaPlay sections')
    table = tables[0]
    if table not in odds[0].iterdescendants():
        raise ValueError('Schedule outside odds section')
    rows = [{'countAttribute': r.get('data-number'),
             'cells': [_text(c) for c in r.xpath('./td')]}
            for r in table.xpath('.//tbody/tr')]
    return {'title': _text(titles[0]), 'rules': _text(rules[0]),
            'oddsText': _text(odds[0]),
            'headers': [_text(c) for c in table.xpath('.//th')], 'rows': rows}


def parse_detail(raw, slug):
    if slug not in SPECS or _extract(raw) != SPECS[slug]:
        raise ValueError('Unreviewed or changed InstaPlay detail')
    spec = SPECS[slug]
    rows = []
    for row in spec['rows']:
        count, prize, odds = row['cells']
        rows.append({'schedulePrizeCount': int(count), 'sourcePrizeLabel': prize,
                     'prizeDollars': None if prize == '$0' else int(prize[1:].replace(',', '')),
                     'prizeStatus': 'unavailable_source_placeholder' if prize == '$0' else 'printed_schedule',
                     'sourceOdds': odds})
    return {'productType': 'instaplay', 'slug': slug,
            'name': spec['title'].removesuffix(' | Idaho Lottery'),
            'sourceUrl': f'https://www.idaholottery.com/games/instaplay/{slug}',
            'rules': spec['rules'], 'sourceOddsText': spec['oddsText'],
            'tiers': rows, 'remainingPrizes': None,
            'limitation': 'Printed schedule counts are not remaining prizes, stock or claims. Source $0 amounts are unavailable placeholders. No current progressive jackpot is inferred.'}
