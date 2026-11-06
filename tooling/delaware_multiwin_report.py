"""Strict source-table observations; not unique-ticket totals or mapped wins."""
from datetime import datetime
import re
from lxml import html

SOURCE = 'https://www.delottery.com/Drawing-Games/Multi-Win-Lotto/Number-Of-Winners'
LABELS = ['Draw Date', '6N', '5N', '4N', '3N', '10+N', '9N', '8N', '7N', '6N', '0N']


def text(node):
    return ' '.join(node.text_content().split())


def parse(raw, *, source_url, observed_date):
    if source_url != SOURCE:
        raise ValueError('Unexpected report source')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != ['Number Of Winners - Multi Win Lotto - Drawing Games | Delaware Lottery']:
        raise ValueError('Unexpected report identity')
    tables = tree.xpath('//table')
    if len(tables) != 1:
        raise ValueError('Expected one report table')
    table = tables[0]
    headers = table.xpath('./thead/tr')
    if len(headers) != 2:
        raise ValueError('Changed grouped headers')
    groups = headers[0].xpath('./th')
    if ([text(n) for n in groups] != ['', 'Win in A Line', 'Combination Win']
            or [n.get('colspan') for n in groups] != [None, '4', '6']
            or [text(n) for n in headers[1].xpath('./th')] != LABELS):
        raise ValueError('Changed report columns')
    rows = []
    previous = None
    for row in table.xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if len(cells) != 11 or [n.get('data-label') for n in cells] != LABELS:
            raise ValueError('Changed row labels or width')
        values = [text(n) for n in cells]
        if not re.fullmatch(r'\d{2}/\d{2}/\d{4}', values[0]):
            raise ValueError('Invalid draw date')
        date = datetime.strptime(values[0], '%m/%d/%Y').date()
        if date > observed_date or (previous is not None and date >= previous):
            raise ValueError('Future, duplicate or unordered draw date')
        previous = date
        if any(not re.fullmatch(r'0|[1-9]\d*', v) for v in values[1:]):
            raise ValueError('Invalid published count')
        rows.append({'drawDate': date.isoformat(), 'categories': [
            {'group': 'Win in A Line' if i < 4 else 'Combination Win',
             'label': LABELS[i + 1], 'publishedCount': int(value)}
            for i, value in enumerate(values[1:])
        ]})
    if not rows:
        raise ValueError('Empty report')
    return {'sourceUrl': SOURCE, 'game': 'Multi-Win Lotto', 'rows': rows,
            'coverage': 'Published category counts; no cross-category sum, unique-ticket total, retailer join or geography inferred.'}
