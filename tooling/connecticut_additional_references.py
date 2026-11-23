"""Source-labelled team prizes and multiplier odds, never ticket counts."""
from html.parser import HTMLParser
import re
from tooling.connecticut_keno_prizes import Tables


class VisibleText(HTMLParser):
    def __init__(self):
        super().__init__(); self.hidden = 0; self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in {'script', 'style'}: self.hidden += 1

    def handle_endtag(self, tag):
        if tag in {'script', 'style'}: self.hidden -= 1

    def handle_data(self, data):
        if not self.hidden: self.parts.append(data)


def parse(html, game):
    if game == 'xsandos':
        p = VisibleText(); p.feed(html)
        text = ' '.join(' '.join(p.parts).split())
        rows = re.findall(r'([4-8]) Teams (JACKPOT|\$[\d,]+) (1 in [\d,]+)', text)
        if len(rows) != 5 or [r[0] for r in rows] != ['8','7','6','5','4']:
            raise ValueError('Missing, duplicate or reordered team prize rows')
        return [{'title': 'Xs & Os reference prizes',
                 'rows': [['Matched teams', 'Prize', 'Odds']] + [list(r) for r in rows],
                 'basis': 'Jackpot is sales-based; prizes may be reduced under official rules. Promotional awards are separate. Not actual payouts or ticket counts.'}]
    p = Tables(); p.feed(html)
    title = 'KENO Bonus Multiplier Odds' if game == 'keno' else 'Multiplier Frequency & Odds'
    matches = [t for t in p.tables if t['title'] == title]
    if len(matches) != 1: raise ValueError('Missing or duplicate multiplier table')
    table = matches[0]; rows = table['rows']
    if game == 'keno':
        if (len(rows) != 2 or rows[0] != ['BONUS MULTIPLIER','NO BONUS','2','3','4','5','10'] or
                len(rows[1]) != 7 or rows[1][0] != 'Odds'):
            raise ValueError('Changed Keno Bonus schema')
        if any(not re.fullmatch(r'1 in \d+(?:\.\d+)?', v) for v in rows[1][1:]):
            raise ValueError('Invalid bonus odds')
        table['rows'] = [['Bonus multiplier', 'Odds']] + [list(pair) for pair in zip(rows[0][1:],rows[1][1:])]
        table['basis'] = 'Source odds of Bonus outcomes, not winning-ticket counts. No Bonus remains a distinct outcome; adding Bonus doubles ticket cost.'
    elif game == 'megamillions':
        if (rows[0] != ['Multiplier Value','Frequency','Odds'] or len(rows) != 6 or
                [r[0] for r in rows[1:]] != ['10X','5X','4X','3X','2X']):
            raise ValueError('Changed Mega Millions multiplier schema')
        for row in rows[1:]:
            if len(row) != 3 or not row[1].isdigit() or not re.fullmatch(r'1 in \d+(?:\.\d+)?',row[2]):
                raise ValueError('Invalid multiplier frequency/odds')
        table['basis'] = 'Reference multiplier distribution per play, not actual winning-play counts. Each play has its own assigned multiplier.'
    else: raise ValueError('Unsupported reference game')
    return [table]
