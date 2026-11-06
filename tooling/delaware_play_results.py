"""Parse Play 3/4/5 monthly observations with explicit source session icons."""
from datetime import date, datetime
import re
from lxml import html


def text(node):
    return ' '.join(node.text_content().split())


def parse(raw, *, digits, year, month, source_url, observed_date):
    if digits not in (3, 4, 5):
        raise ValueError('Unsupported positional game')
    month_start = date(year, month, 1)
    expected_url = f'https://www.delottery.com/Winning-Numbers/Search-Winners/{year}/{month}/Play{digits}'
    if source_url != expected_url or month_start > observed_date:
        raise ValueError('Source/month mismatch')
    tree = html.fromstring(raw)
    title = f'{month_start:%B %Y} - Play {digits} - Search Winners | Delaware Lottery'
    if tree.xpath('//title/text()') != [title]:
        raise ValueError('Wrong monthly game identity')
    tables = tree.xpath('//table')
    if len(tables) != 1:
        raise ValueError('Expected one result table')
    table = tables[0]
    labels = ['Game', 'Date', 'Winning Numbers']
    if [text(n) for n in table.xpath('./thead/tr/th')] != labels:
        raise ValueError('Changed table headers')
    results, seen, previous = [], set(), None
    for row in table.xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if len(cells) != 3 or [n.get('data-label') for n in cells] != labels:
            raise ValueError('Changed row contract')
        if text(cells[0]) != f'Play {digits}':
            raise ValueError('Wrong row game identity')
        icons = cells[0].xpath('./i')
        if len(icons) != 1:
            raise ValueError('Missing or ambiguous session')
        classes = set(icons[0].get('class', '').split())
        tokens = classes & {'li-sun', 'li-moon'}
        if len(tokens) != 1:
            raise ValueError('Unknown session icon')
        session = 'day' if 'li-sun' in tokens else 'night'
        literal_date = text(cells[1])
        if not re.fullmatch(r'\d{2}/\d{2}/\d{2}', literal_date):
            raise ValueError('Invalid source date')
        draw_date = datetime.strptime(literal_date, '%m/%d/%y').date()
        if (draw_date.year, draw_date.month) != (year, month) or draw_date > observed_date:
            raise ValueError('Out-of-month or future result')
        identity = (draw_date, session)
        if identity in seen or (previous is not None and draw_date > previous):
            raise ValueError('Duplicate or unordered result')
        seen.add(identity)
        previous = draw_date
        lists = cells[2].xpath('./ul')
        if len(lists) != 1 or len(cells[2]) != 1:
            raise ValueError('Unexpected result structure')
        balls = lists[0].xpath('./li')
        values = [text(n) for n in balls]
        if len(values) != digits or any(not re.fullmatch(r'\d', v, re.ASCII) for v in values):
            raise ValueError('Invalid positional digits')
        if any(len(n) or n.get('class', '').strip() for n in balls):
            raise ValueError('Unexpected digit annotation')
        results.append({'game': f'Play {digits}', 'session': session,
                        'drawDate': draw_date.isoformat(), 'digits': values})
    if not results:
        raise ValueError('No observed monthly results')
    return {'sourceUrl': source_url, 'results': results,
            'coverage': 'Observed monthly rows; missing sessions are unavailable, never zero or synthesized.'}
