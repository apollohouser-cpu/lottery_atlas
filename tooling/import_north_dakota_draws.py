"""Strict ND date-only result tables. No inferred instants, counts or payouts."""
from datetime import date, datetime, timezone
from html.parser import HTMLParser
import re
from zoneinfo import ZoneInfo

# Reviewed capture boundary, not game inception or a historical format change.
SUPPORTED_FROM = date(2026, 9, 1)
SPECS = {
    'powerball': ('Powerball', 'PowerBall', ['Draw Date', 'Winning Numbers', 'PowerBall', 'Power Play', 'Jackpot'], 5, 69, 1, 26, {0, 2, 5}),
    'mega-millions': ('Mega Millions', 'MegaMillions', ['Draw Date', 'Winning Numbers', 'Mega Ball', 'Megaplier', 'Jackpot'], 5, 70, 1, 24, {1, 4}),
    'millionaire-for-life': ('MILLIONAIRE FOR LIFE™', 'MillionaireForLife', ['Draw Date', 'Winning Numbers', 'Millionaire Ball™'], 5, 58, 1, 5, set(range(7))),
    'lotto-america': ('Lotto America', 'LottoAmerica', ['Draw Date', 'Winning Numbers', 'Star Ball', 'All Star Bonus', 'Jackpot'], 5, 52, 1, 10, {0, 2, 5}),
    '2by2': ('2BY2', 'TwoByTwo', ['Draw Date', 'Red Balls', 'White Balls'], 2, 26, 2, 26, set(range(7))),
}


def source_url(game):
    return 'https://www.lottery.nd.gov/public/games/' + SPECS[game][1] + 'WinningNumbers'


class ResultTable(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables, self.headings = [], []
        self.table = self.row = self.cell = self.heading = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'h1':
            if self.heading is not None:
                raise ValueError('Nested heading')
            self.heading = []
        elif tag == 'table':
            if self.table is not None:
                raise ValueError('Nested table')
            self.table = []
        elif tag == 'tr' and self.table is not None:
            if self.row is not None:
                raise ValueError('Unclosed row')
            self.row = []
        elif tag in ('th', 'td') and self.table is not None:
            if self.row is None or self.cell is not None:
                raise ValueError('Invalid cell structure')
            if any(attrs.get(k, '1') != '1' for k in ('rowspan', 'colspan')):
                raise ValueError('Unexpected merged result cell')
            self.cell = []

    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)
        if self.heading is not None:
            self.heading.append(data)

    def handle_endtag(self, tag):
        if tag == 'h1' and self.heading is not None:
            self.headings.append(' '.join(''.join(self.heading).split()))
            self.heading = None
        elif tag in ('th', 'td') and self.table is not None:
            if self.cell is None:
                raise ValueError('Unexpected cell close')
            self.row.append(' '.join(''.join(self.cell).split()))
            self.cell = None
        elif tag == 'tr' and self.table is not None:
            if self.row is None or self.cell is not None:
                raise ValueError('Invalid row close')
            self.table.append(self.row)
            self.row = None
        elif tag == 'table':
            if self.table is None or self.row is not None:
                raise ValueError('Invalid table close')
            self.tables.append(self.table)
            self.table = None


def _numbers(text, count, maximum):
    if not re.fullmatch(r'[1-9]\d*(?:-[1-9]\d*)*', text):
        raise ValueError('Invalid numbers')
    values = list(map(int, text.split('-')))
    if len(values) != count or len(set(values)) != count or any(n > maximum for n in values):
        raise ValueError('Wrong number cardinality/range')
    return values


def parse_draws(html, game, *, retrieved_at):
    if game not in SPECS or not isinstance(html, str):
        raise ValueError('Unsupported game/input')
    captured = datetime.fromisoformat(retrieved_at.replace('Z', '+00:00'))
    if captured.tzinfo is None or captured.utcoffset().total_seconds() != 0:
        raise ValueError('Capture must be UTC')
    title, _, headers, count, maximum, bonus_count, bonus_max, days = SPECS[game]
    parser = ResultTable()
    parser.feed(html)
    parser.close()
    if any(x is not None for x in (parser.table, parser.row, parser.cell, parser.heading)):
        raise ValueError('Unclosed source markup')
    if parser.headings != [title] or len(parser.tables) != 1:
        raise ValueError('Wrong page identity/table count')
    table = parser.tables[0]
    if not table or table[0] != headers or len(table) < 3:
        raise ValueError('Wrong headers or fewer than two results')
    output, previous = [], None
    for cells in table[1:]:
        if len(cells) != len(headers) or not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}', cells[0]):
            raise ValueError('Wrong result shape/date')
        month, day, year = map(int, cells[0].split('/'))
        drawn = date(year, month, day)
        if (drawn < SUPPORTED_FROM or drawn > captured.astimezone(ZoneInfo('America/Chicago')).date()
                or drawn.weekday() not in days or (previous is not None and drawn >= previous)):
            raise ValueError('Unsupported/future/duplicate/out-of-order drawing date')
        previous = drawn
        primary = _numbers(cells[1], count, maximum)
        bonus = _numbers(cells[2], bonus_count, bonus_max)
        multiplier = None
        if game in ('powerball', 'lotto-america'):
            allowed = ('2', '3', '4', '5', '10') if game == 'powerball' else ('2', '3', '4', '5')
            if cells[3] not in allowed:
                raise ValueError('Invalid draw multiplier')
            multiplier = int(cells[3])
        elif game == 'mega-millions' and cells[3] != 'N/A':
            raise ValueError('Legacy Megaplier must be unavailable')
        if len(headers) == 5 and not re.fullmatch(r'\$[1-9]\d{0,2}(?:,\d{3})*', cells[4]):
            raise ValueError('Unexpected advertised jackpot structure')
        output.append({'game': game, 'drawDate': drawn.isoformat(), 'datePrecision': 'day',
                       'numbers': primary, 'bonusNumbers': bonus,
                       'numberLabels': ['Red', 'White'] if game == '2by2' else ['Main', 'Bonus'],
                       'multiplier': multiplier, 'sourceUrl': source_url(game),
                       'sourceRetrievedAt': captured.astimezone(timezone.utc).isoformat(),
                       'reportStatus': 'unavailable'})
    return output
