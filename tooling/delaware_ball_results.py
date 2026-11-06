"""Strict monthly Multi-Win, Mega Millions and Lotto America observations."""
from datetime import date, datetime
import re
from lxml import html

SPECS = {
    'MultiWin': ('Multi Win', 'Multi-Win Lotto', 6, 35, None, None),
    'MegaMillions': ('Mega Millions', 'Mega Millions', 5, 70, 24, 'ball-color-yellow-orange'),
    'LottoAmerica': ('Lotto America', 'Lotto America', 5, 52, 10, 'ball-color-blue'),
}


def text(n):
    return ' '.join(n.text_content().split())


def parse(raw, *, game, year, month, source_url, observed_date):
    if game not in SPECS:
        raise ValueError('Unsupported game')
    title_name, row_name, count, maximum, special_max, special_class = SPECS[game]
    start = date(year, month, 1)
    if source_url != f'https://www.delottery.com/Winning-Numbers/Search-Winners/{year}/{month}/{game}' or start > observed_date:
        raise ValueError('Source/month mismatch')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != [f'{start:%B %Y} - {title_name} - Search Winners | Delaware Lottery']:
        raise ValueError('Wrong page identity')
    tables = tree.xpath('//table')
    labels = ['Game', 'Date', 'Winning Numbers']
    if len(tables) != 1 or [text(n) for n in tables[0].xpath('./thead/tr/th')] != labels:
        raise ValueError('Changed result table')
    results, previous = [], None
    for row in tables[0].xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if len(cells) != 3 or [n.get('data-label') for n in cells] != labels:
            raise ValueError('Changed row labels')
        if ' '.join((cells[0].text or '').split()) != row_name:
            raise ValueError('Wrong row game')
        raw_date = text(cells[1])
        if not re.fullmatch(r'\d{2}/\d{2}/\d{2}', raw_date):
            raise ValueError('Invalid date')
        draw = datetime.strptime(raw_date, '%m/%d/%y').date()
        if (draw.year, draw.month) != (year, month) or draw > observed_date or (previous and draw >= previous):
            raise ValueError('Future, duplicate, unordered or out-of-month date')
        previous = draw
        lists = cells[2].xpath('./ul')
        if len(lists) != 1:
            raise ValueError('Missing/ambiguous number list')
        balls = lists[0].xpath('./li')
        if len(balls) != count + bool(special_max):
            raise ValueError('Wrong number count')
        if any(len(n) or not re.fullmatch(r'\d{2}', text(n), re.ASCII) for n in balls):
            raise ValueError('Invalid numeric token')
        if any(n.get('class', '').strip() for n in balls[:count]):
            raise ValueError('Unexpected base ball annotation')
        numbers = [int(text(n)) for n in balls[:count]]
        if len(set(numbers)) != count or any(not 1 <= n <= maximum for n in numbers):
            raise ValueError('Invalid base numbers')
        result = {'game': row_name, 'drawDate': draw.isoformat(), 'numbers': numbers}
        if special_max:
            special = int(text(balls[-1]))
            if balls[-1].get('class', '').split() != [special_class] or not 1 <= special <= special_max:
                raise ValueError('Invalid special ball identity/range')
            result['specialBall'] = special
        paragraphs = cells[2].xpath('./p')
        if game == 'LottoAmerica':
            if len(paragraphs) != 1 or len(paragraphs[0].xpath('./strong')) != 1:
                raise ValueError('Missing multiplier')
            if text(paragraphs[0]).split()[0] != 'Multiplier®':
                raise ValueError('Wrong multiplier label')
            multiplier = text(paragraphs[0].xpath('./strong')[0])
            if multiplier not in {'2X', '3X', '4X', '5X'}:
                raise ValueError('Unknown All Star multiplier')
            result['allStarBonus'] = int(multiplier[0])
        elif paragraphs:
            raise ValueError('Unexpected drawing multiplier')
        if len(cells[2]) != 1 + len(paragraphs):
            raise ValueError('Unexpected result content')
        results.append(result)
    if not results:
        raise ValueError('No observed results')
    return {'sourceUrl': source_url, 'results': results}
