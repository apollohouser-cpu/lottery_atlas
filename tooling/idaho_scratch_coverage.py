"""Complete Scratch collection with a separately reviewed unavailable game type."""
import copy
import json
from pathlib import Path
from lxml import html
from tooling import import_idaho_scratch_catalog as base

SPEC = json.loads(Path(__file__).with_name('idaho_scratch_unavailable_spec.json').read_text())


def _card(card):
    return {'id': card.get('data-game-id'),
            'name': base.text(base.one(card, './/h5')),
            'path': base.one(card, './/a[@class="image-link"]/@href'),
            'price': base.text(base.one(card, './/span[@class="game__info-price"]')),
            'topPrize': base.text(base.one(card, './/span[@class="game__info-top-prize-value"]')),
            'headers': [base.text(c) for c in card.xpath('.//table[@class="scratch-prizes"]//th')],
            'rows': [[base.text(c) for c in r.xpath('./td')] for r in card.xpath('.//table[@class="scratch-prizes"]//tbody/tr')]}


def _detail(raw):
    doc = html.fromstring(raw)
    section = base.one(doc, '//section[contains(concat(" ",normalize-space(@class)," ")," section-game ")]')
    table = base.one(section, './/table[contains(@class,"prize-chart-table")]')
    return {'name': base.text(base.one(section, './/header//h5')),
            'images': section.xpath('.//img/@src'),
            'badges': [base.text(n) for n in section.xpath('.//ul[@class="list-badges"]/li')],
            'headers': [base.text(n) for n in table.xpath('./thead/tr/th')],
            'rows': [[base.text(c) for c in r.xpath('./td')] for r in table.xpath('./tbody/tr')],
            'qualification': base.text(base.one(section, './/*[@id="tab3"]'))}


def build_scratch(listing, claims_raw, fetch_detail, *, as_of):
    doc = html.fromstring(listing)
    if doc.xpath('//*[contains(@class,"pager__item--next")]'):
        raise ValueError('Unexpected Scratch pagination')
    claims = base.parse_claims(claims_raw)
    cards = doc.xpath('//li[@data-game-id]')
    if not cards or len({c.get('data-game-id') for c in cards}) != len(cards):
        raise ValueError('Empty/duplicate Scratch identity')
    games, unavailable, excluded = [], [], []
    for card in cards:
        identity = _card(card)
        # Existing numeric validator remains authoritative whenever counts exist.
        blank = any(len(r) == 2 and r[1] == '' for r in identity['rows'])
        if blank:
            if identity != SPEC['card']:
                raise ValueError('Unreviewed blank Scratch inventory')
            raw = fetch_detail(base.ROOT + identity['path'])
            if _detail(raw) != SPEC['detail']:
                raise ValueError('Changed unavailable Scratch detail')
            if as_of.isoformat() < SPEC['startDate'] or identity['id'] in claims:
                raise ValueError('Unavailable game status needs review')
            unavailable.append(copy.deepcopy(SPEC['projection']))
        else:
            game = base.parse_catalog(html.tostring(card))[identity['id']]
            result = base.parse_detail(fetch_detail(base.ROOT+game['path']),game,claims,as_of)
            if result is None: excluded.append(game['id'])
            else: games.append(result)
    return {'games': games, 'unavailableInventoryGames': unavailable,
            'excludedByDates': excluded, 'listedGameCount': len(cards), 'sourceDate': None}
