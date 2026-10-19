"""Separate typed $50-plus cumulative source reports, never stock or dated claims."""
from datetime import date, datetime
import re
from lxml import html
from tooling.import_iowa_scratch_catalog import SOURCE, plain, count

TYPES = ('Scratch', 'InstaPlay', 'PullTab')
ROUTES = {
    'Scratch': SOURCE,
    'InstaPlay': 'https://www.ialottery.com/Pages/Games-Instaplay/Instaplay.aspx',
    'PullTab': 'https://www.ialottery.com/Pages/Games-Pulltab/PulltabGamesListing.aspx',
}


def parse_inventories(raw, *, as_of):
    if type(as_of) is not date:
        raise ValueError('Calendar date required')
    tree = html.fromstring(raw)
    dates = tree.xpath('//*[@id="ContentPlaceHolder1_DataAsOf"]/text()')
    if len(dates) != 1 or not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}', dates[0].strip()):
        raise ValueError('Invalid source date')
    day = datetime.strptime(dates[0].strip(), '%m/%d/%Y').date()
    if day > as_of:
        raise ValueError('Future source date')
    tables = tree.xpath('//table[@id="RemainPrizes_JS_DATATABLE"]')
    if len(tables) != 1:
        raise ValueError('Missing or ambiguous prize report')
    if [plain(x) for x in tables[0].xpath('./thead/tr/th')] != ['Game Name (Game Number)', 'Game Type', 'Cost', 'Prize', 'Claimed', 'Unclaimed']:
        raise ValueError('Changed report columns')
    typed = {kind: {} for kind in TYPES}
    for row in tables[0].xpath('./tbody/tr'):
        cells = [plain(x) for x in row.xpath('./td')]
        if len(cells) != 6:
            raise ValueError('Incomplete prize row')
        name, kind, price, prize, claimed, unclaimed = cells
        if kind not in typed:
            raise ValueError('Unknown product type')
        match = re.fullmatch(r'(.+?)\s+\((\d+)\)', name)
        if not match or not re.fullmatch(r'\$\d+', prize):
            raise ValueError('Invalid source identity/prize')
        cost, amount = count(price), count(prize[1:])
        if cost <= 0 or amount < 50:
            raise ValueError('Invalid price or changed threshold')
        game = typed[kind].setdefault(match[2], dict(id=match[2], productType=kind, name=match[1], cost=cost, prizeTiers=[]))
        if (game['name'], game['cost']) != (match[1], cost):
            raise ValueError('Conflicting typed identity')
        if any(t['prizeAmount'] == amount for t in game['prizeTiers']):
            raise ValueError('Duplicate typed tier')
        game['prizeTiers'].append(dict(prizeAmount=amount, claimed=count(claimed), unclaimed=count(unclaimed)))
    if any(not games for games in typed.values()):
        raise ValueError('Missing product subset')
    return dict(state='Iowa', sourceUrl=SOURCE, sourceDate=day.isoformat(),
                coverage='Published $50-plus cumulative claimed/unclaimed report subsets, not complete prize schedules, dated claims or store stock. Progressive jackpots and below-$50 tiers are not represented.',
                inventories=[dict(productType=kind, officialRoute=ROUTES[kind],
                                  games=sorted(games.values(), key=lambda g: int(g['id'])))
                             for kind, games in typed.items()])
