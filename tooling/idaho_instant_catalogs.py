"""Complete reviewed InstaPlay/Tab list-to-detail joins, without inventory claims."""
import json
from decimal import Decimal
from pathlib import Path
from lxml import html
from tooling.idaho_instaplay import parse_detail as parse_instaplay
from tooling.idaho_tabs import parse_detail as parse_tab

SPECS = json.loads(Path(__file__).with_name('idaho_instant_catalog_specs.json').read_text())


def _extract(raw, kind):
    doc = html.fromstring(raw)
    if doc.xpath('//head/title/text()') != ['Games | Idaho Lottery']:
        raise ValueError('Wrong catalog title')
    rows = []
    for r in doc.xpath('//tr[@data-game-id]'):
        links = r.xpath('./td[@data-title="Name"]/a')
        prices = r.xpath('./td[@data-title="Price"]')
        if len(links) != 1 or len(prices) != 1:
            raise ValueError('Malformed catalog row')
        rows.append({'sourceGameId': r.get('data-game-id'), 'sourceType': r.get('data-game-type'),
                     'path': links[0].get('href'), 'name': ' '.join(links[0].text_content().split()),
                     'priceLabel': ' '.join(prices[0].text_content().split())})
    # Grid and table links must describe the same catalog, including new games.
    paths = set(doc.xpath(f'//a[starts-with(@href,"/games/{kind}/")]/@href'))
    if kind == 'instaplay':
        paths -= {f'/games/instaplay/{suffix}' for suffix in ['all/1', '1', '2', '3', '5', '10', '20', '30']}
    if paths != {r['path'] for r in rows}:
        raise ValueError('Grid/table catalog mismatch')
    return rows


def parse_listing(raw, kind):
    if kind not in SPECS:
        raise ValueError('Unsupported catalog type')
    rows = _extract(raw, kind)
    if rows != SPECS[kind]:
        raise ValueError('Changed catalog requires review')
    return rows


def build_catalog(raw, kind, fetch_detail):
    rows = parse_listing(raw, kind)
    parser = parse_instaplay if kind == 'instaplay' else parse_tab
    games = []
    for row in rows:
        url = 'https://www.idaholottery.com' + row['path']
        game = parser(fetch_detail(url), row['path'].rsplit('/', 1)[1])
        if game['name'] != row['name'] or game['sourceUrl'] != url:
            raise ValueError('Catalog/detail identity mismatch')
        game.update({'sourceGameId': row['sourceGameId'] or None,
                     'listedPriceCents': int(Decimal(row['priceLabel'][1:]) * 100),
                     'sourcePriceLabel': row['priceLabel'],
                     'listedPriceMeaning': 'Listed catalog price; TouchTab wager options are separate schedule rows.'})
        games.append(game)
    return {'productType': kind, 'games': games, 'remainingPrizes': None}
