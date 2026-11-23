"""Expand captured HTML wager matrices without calculating or inventing prizes."""
from html.parser import HTMLParser


class Matrices(HTMLParser):
    def __init__(self):
        super().__init__(); self.tables = []; self.table = None; self.row = None; self.cell = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'table':
            if self.table is not None: raise ValueError('Nested prize matrix')
            if 'prize-chart-table' not in a.get('class','').split(): raise ValueError('Unexpected matrix')
            self.table = []
        elif self.table is not None and tag == 'tr': self.row = []
        elif self.row is not None and tag in {'td','th'}:
            spans = [int(a.get(k,'1')) for k in ['rowspan','colspan']]
            if any(n < 1 or n > 20 for n in spans): raise ValueError('Invalid span')
            self.cell = {'parts':[], 'rowspan':spans[0], 'colspan':spans[1]}
        elif self.cell is not None and tag in {'br','p'}: self.cell['parts'].append(' ')

    def handle_data(self, data):
        if self.cell is not None: self.cell['parts'].append(data)

    def handle_endtag(self, tag):
        if tag in {'td','th'} and self.cell is not None:
            self.cell['text'] = ' '.join(''.join(self.cell.pop('parts')).split())
            self.row.append(self.cell); self.cell = None
        elif tag == 'tr' and self.row is not None:
            self.table.append(self.row); self.row = None
        elif tag == 'table' and self.table is not None:
            self.tables.append(self.table); self.table = None


def expand(rows):
    pending = {}; result = []; width = None
    for cells in rows:
        values = {col: value for col, (value, remaining) in pending.items()}
        pending = {col: (value, remaining-1) for col,(value,remaining) in pending.items() if remaining > 1}
        col = 0
        for cell in cells:
            while col in values: col += 1
            for offset in range(cell['colspan']):
                target = col + offset
                if target in values: raise ValueError('Overlapping span')
                values[target] = cell['text']
                if cell['rowspan'] > 1: pending[target] = (cell['text'],cell['rowspan']-1)
            col += cell['colspan']
        if width is None: width = len(values)
        if sorted(values) != list(range(width)): raise ValueError('Ragged matrix')
        result.append([values[i] for i in range(width)])
    if pending: raise ValueError('Unterminated row span')
    return result


def parse(html, game):
    if game not in {'play3','play4'}: raise ValueError('Not a digit game')
    parser = Matrices(); parser.feed(html)
    if len(parser.tables) != 4: raise ValueError('Expected four wager matrices')
    titles = ['Base game without Wild Ball', 'Combo without Wild Ball',
              'Base game with Wild Ball', 'Combo with Wild Ball']
    output = []
    for index, (cells, title) in enumerate(zip(parser.tables,titles)):
        rows = expand(cells)
        if len(rows) < 3: raise ValueError('Empty wager matrix')
        if index in {0,2}:
            if rows[0][-10:] != [f'${n/2:.2f}' for n in range(1,11)]: raise ValueError('Changed wager columns')
        elif rows[0] != ['Example','Match','Wager','Combo Prize']:
            raise ValueError('Changed Combo columns')
        # Blank decorative header is explicitly marked; no prize is synthesized.
        rows[0] = [label or 'Source description' for label in rows[0]]
        output.append({'title': f'{game.title()} — {title}', 'rows': rows,
            'basis': 'Captured reference schedule. Wager and Wild Ball cost distinctions remain as published. A dash is not a zero prize; repeated cells preserve source row/column spans. Not actual payouts or winning-ticket counts.'})
    return output
