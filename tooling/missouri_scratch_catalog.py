"""Validate Missouri's public inventory while retaining advertised prize semantics.

This module does not publish app data or infer cash options, claim dates, or stock.
"""
from datetime import datetime
import re
from lxml import html


def plain(node):
    return ' '.join(node.text_content().split())


def one(nodes, label):
    if len(nodes) != 1:
        raise ValueError('Expected exactly one ' + label)
    return nodes[0]


def integer(value, money=False):
    pattern = r'\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)' if money else r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)'
    if not re.fullmatch(pattern, value):
        raise ValueError('Invalid amount/count: ' + value)
    return int(value.replace('$', '').replace(',', ''))


def source_date(value):
    if value == 'TBD':
        return None
    try:
        return datetime.strptime(value, '%b %d, %Y').date().isoformat()
    except ValueError as error:
        raise ValueError('Invalid source date') from error


def parse_listing(raw):
    tree = html.fromstring(raw)
    grid = one(tree.xpath('//div[contains(concat(" ",normalize-space(@class)," ")," scratchers-list_big-list ")]'), 'main game grid')
    cards = grid.xpath('./div[@class="scratchers-list__item"]')
    if not cards:
        raise ValueError('Empty game grid')
    games = []
    for card in cards:
        gid = plain(one(card.xpath('.//div[@class="scratchers-list__num"]'), 'game ID'))
        if not re.fullmatch(r'#\s*[1-9]\d*', gid):
            raise ValueError('Invalid game ID')
        gid = gid.replace('#', '').strip()
        name = plain(one(card.xpath('.//div[@class="scratchers-list__title"]'), 'game name'))
        fields = {}
        for f in card.xpath('.//div[@class="scratchers-list__feature"]'):
            key = plain(one(f.xpath('./div[@class="scratchers-list__subtitle"]'), 'field label'))
            if key in fields:
                raise ValueError('Duplicate listing field')
            fields[key] = plain(one(f.xpath('./div[@class="scratchers-list__value"]'), 'field value'))
        required = {'Start Date:', 'End Date:', 'Ticket Price:', 'Top Prize:', 'Total Won:', 'Total Unclaimed:'}
        if set(fields) != required or not name:
            raise ValueError('Changed listing fields')
        start, end = source_date(fields['Start Date:']), source_date(fields['End Date:'])
        price, top = integer(fields['Ticket Price:'], True), integer(fields['Top Prize:'], True)
        if not start or (end and end < start) or not price or not top:
            raise ValueError('Invalid listing dates or amounts')
        rows = [[plain(n) for n in r.xpath('./td')] for r in card.xpath('.//tbody/tr')]
        if not rows or any(len(r) != 3 for r in rows):
            raise ValueError('Invalid listed top tiers')
        games.append(dict(id=gid, name=name, fields=fields, startDate=start, endDate=end,
                          ticketPrice=price, advertisedTopPrize=fields['Top Prize:'], listedTiers=rows))
    if len({g['id'] for g in games}) != len(games):
        raise ValueError('Duplicate main-grid game')
    return games


def validate_detail(raw, game):
    tree = html.fromstring(raw)
    identity = one(tree.xpath('//div[@class="scratchers-single__id"]'), 'detail ID')
    if plain(identity) != 'Game #' + game['id'] or plain(one(identity.getparent().xpath('./h1'), 'detail name')).casefold() != game['name'].casefold():
        raise ValueError('Detail identity mismatch')
    fields = {}
    for block in tree.xpath('//div[@class="scratchers-single-info__block"]'):
        key = plain(one(block.xpath('./div[@class="scratchers-single-info__title"]'), 'detail label'))
        if key in fields:
            raise ValueError('Duplicate detail field')
        fields[key] = plain(one(block.xpath('./div[@class="scratchers-single-info__body"]'), 'detail value'))
    for detail, listing in [('Official Start Date:', 'Start Date:'), ('End Date:', 'End Date:'), ('Ticket Price:', 'Ticket Price:')]:
        if fields.get(detail) != game['fields'][listing]:
            raise ValueError('Detail date/price mismatch')
    table = one(tree.xpath('//table[contains(@class,"table_highlight-first")]'), 'prize table')
    if [plain(n) for n in table.xpath('./thead/tr/th')] != ['Prize Level', 'Total Prizes', 'Unclaimed Prizes']:
        raise ValueError('Changed prize columns')
    tiers = []
    for row in table.xpath('./tbody/tr'):
        cells = [plain(n) for n in row.xpath('./td')]
        if len(cells) != 3:
            raise ValueError('Incomplete tier')
        prize, total, unclaimed = integer(cells[0], True), integer(cells[1]), integer(cells[2])
        if prize <= 0 or unclaimed > total:
            raise ValueError('Impossible inventory')
        tiers.append(dict(prizeLabel=cells[0], advertisedAmount=prize, totalPrizes=total, unclaimedPrizes=unclaimed))
    by = {t['advertisedAmount']: t for t in tiers}
    if not tiers or len(by) != len(tiers) or max(by) != integer(game['advertisedTopPrize'], True):
        raise ValueError('Duplicate tiers or inconsistent top prize')
    for prize, total, unclaimed in game['listedTiers']:
        t = by.get(integer(prize, True))
        if t is None or (t['totalPrizes'], t['unclaimedPrizes']) != (integer(total), integer(unclaimed)):
            raise ValueError('Listing/detail inventory mismatch')
    body = ' '.join(' '.join(tree.xpath('//body//text()[not(ancestor::script) and not(ancestor::style)]')).split())
    if 'The information on this page is updated daily.' not in body:
        raise ValueError('Missing inventory cadence disclosure')
    return dict(id=game['id'], name=game['name'], ticketPrice=game['ticketPrice'],
                startDate=game['startDate'], endDate=game['endDate'], sourceDate=None,
                advertisedTopPrize=game['advertisedTopPrize'], prizeTiers=tiers,
                coverage='Estimated unclaimed inventory; advertised prize amounts are not verified immediate cash values. No claim dates, retailer stock or winning-ticket total derived.')
