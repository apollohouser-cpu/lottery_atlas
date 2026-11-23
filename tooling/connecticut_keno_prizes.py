"""Parse literal Keno spot reference tables; never infer winner counts."""
from html.parser import HTMLParser
import re


class Tables(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.active = None
        self.row = None
        self.cell = None
        self.tables = []

    def handle_starttag(self, tag, attrs):
        if tag != 'div':
            return
        self.depth += 1
        a = dict(attrs)
        role = a.get('role')
        if role == 'table':
            if self.active is not None:
                raise ValueError('Nested table')
            self.active = dict(title=a.get('aria-label'), rows=[], depth=self.depth)
        elif self.active is not None and role == 'row':
            if self.row is not None:
                raise ValueError('Nested row')
            self.row = dict(cells=[], depth=self.depth)
        elif self.row is not None and role in {'cell', 'columnheader'}:
            if self.cell is not None:
                raise ValueError('Nested cell')
            self.cell = dict(text=[], depth=self.depth)

    def handle_data(self, data):
        if self.cell is not None:
            self.cell['text'].append(data)

    def handle_endtag(self, tag):
        if tag != 'div':
            return
        if self.cell is not None and self.cell['depth'] == self.depth:
            self.row['cells'].append(' '.join(''.join(self.cell['text']).split()))
            self.cell = None
        if self.row is not None and self.row['depth'] == self.depth:
            self.active['rows'].append(self.row['cells'])
            self.row = None
        if self.active is not None and self.active['depth'] == self.depth:
            self.tables.append({k: self.active[k] for k in ['title', 'rows']})
            self.active = None
        self.depth -= 1


def parse(html):
    parser = Tables(); parser.feed(html)
    tables = [t for t in parser.tables if re.fullmatch(r'(?:10|[1-9])-Spot Game', t['title'] or '')]
    if len(tables) != 10 or {t['title'] for t in tables} != {f'{n}-Spot Game' for n in range(1, 11)}:
        raise ValueError('Incomplete or duplicate Keno spot tables')
    for table in tables:
        rows = table['rows']
        if not rows or rows[0] != ['Match', 'Prize', 'Odds']:
            raise ValueError('Changed Keno headers')
        spot = int(table['title'].split('-')[0])
        seen = set()
        for row in rows[1:]:
            if len(row) != 3 or not row[0].isdigit() or not 0 <= int(row[0]) <= spot or row[0] in seen:
                raise ValueError('Invalid Keno match row')
            seen.add(row[0])
            if not re.fullmatch(r'\$[\d,]+(?:\.\d{1,2})?', row[1]) or not re.fullmatch(r'1 in [\d,]+', row[2]):
                raise ValueError('Invalid Keno prize/odds')
        if not seen:
            raise ValueError('Empty Keno prizes')
        table['basis'] = '$1 play without Bonus; reference prizes, not actual payouts or winning-ticket counts.'
    return tables
