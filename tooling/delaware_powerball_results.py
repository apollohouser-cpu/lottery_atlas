"""Keep Powerball and Double Play separate in Delaware's paired monthly rows."""
from datetime import date, datetime
import re
from lxml import html
from tooling.delaware_keno_results import nodes


def text(n):
    return ' '.join(n.text_content().split())


def one(row, cls):
    found = nodes(row, cls)
    if len(found) != 1:
        raise ValueError('Missing or ambiguous ' + cls)
    return found[0]


def balls(container, *, secondary):
    lists = nodes(container, 'powerball-search-results-balls')
    if len(lists) != 1:
        raise ValueError('Missing or duplicate ball list')
    children = list(lists[0])
    if len(children) != 6 or any(n.tag != ('div' if secondary else 'li') or len(n) for n in children):
        raise ValueError('Changed ball structure')
    values = [text(n) for n in children]
    if any(not re.fullmatch(r'\d{2}', v, re.ASCII) for v in values):
        raise ValueError('Invalid ball token')
    expected = ['ball-color-black' if secondary else ''] * 5 + ['ball-color-red']
    if [n.get('class', '').strip() for n in children] != expected:
        raise ValueError('Changed base/special ball roles')
    values = list(map(int, values))
    if len(set(values[:5])) != 5 or any(not 1 <= v <= 69 for v in values[:5]) or not 1 <= values[5] <= 26:
        raise ValueError('Invalid drawn numbers')
    return {'numbers': values[:5], 'powerball': values[5]}


def parse(raw, *, year, month, source_url, observed_date):
    start = date(year, month, 1)
    if source_url != f'https://www.delottery.com/Winning-Numbers/Search-Winners/{year}/{month}/PowerBall' or start > observed_date:
        raise ValueError('Source/month mismatch')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != [f'{start:%B %Y} - Power Ball - Search Winners | Delaware Lottery']:
        raise ValueError('Wrong monthly identity')
    tables = tree.xpath('//table')
    labels = ['Game', 'Date', 'Winning Numbers']
    if len(tables) != 1 or [text(n) for n in tables[0].xpath('./thead/tr/th')] != labels:
        raise ValueError('Changed table')
    results, previous = [], None
    for row in tables[0].xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if len(cells) != 3 or [n.get('data-label') for n in cells] != labels:
            raise ValueError('Changed row labels')
        label = one(cells[0], 'powerball-search-results-main-label')
        if [text(n) for n in label.xpath('./div')] != ['Powerball'] or text(one(cells[0], 'powerball-double-play-label')) != 'Double play®':
            raise ValueError('Changed paired game labels')
        raw_date = text(one(cells[1], 'powerball-date-value'))
        if text(one(cells[1], 'powerball-search-results-secondary-date')):
            raise ValueError('Unexpected separate Double Play date')
        if not re.fullmatch(r'\d{2}/\d{2}/\d{2}', raw_date):
            raise ValueError('Malformed date')
        draw = datetime.strptime(raw_date, '%m/%d/%y').date()
        if (draw.year, draw.month) != (year, month) or draw > observed_date or (previous and draw >= previous):
            raise ValueError('Invalid date order/bounds')
        previous = draw
        primary = one(cells[2], 'powerball-search-results-primary-balls')
        secondary = one(cells[2], 'powerball-search-results-secondary-balls')
        powerplay = one(primary, 'powerball-search-results-power-play')
        if len(powerplay.xpath('./strong')) != 1 or len(powerplay.xpath('./span')) != 1 or text(powerplay.xpath('./span')[0]) != 'Power play®':
            raise ValueError('Changed Power Play label')
        value = text(powerplay.xpath('./strong')[0])
        if value not in {'2X', '3X', '4X', '5X', '10X'}:
            raise ValueError('Invalid Power Play multiplier')
        if len(nodes(secondary, 'powerball-search-results-balls')) != len(secondary) or secondary.xpath('.//p'):
            raise ValueError('Unexpected Double Play metadata')
        results.extend([
            dict(game='Powerball', drawDate=draw.isoformat(), powerPlay=int(value[:-1]), **balls(primary, secondary=False)),
            dict(game='Double Play', drawDate=draw.isoformat(), **balls(secondary, secondary=True)),
        ])
    if not results:
        raise ValueError('No observed results')
    return {'sourceUrl': source_url, 'results': results}
