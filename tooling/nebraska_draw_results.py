"""Strict bounded official Nebraska number tables (no inferred prize reports)."""
from datetime import date, datetime
import re
from urllib.parse import quote_plus
from lxml import html

# Each group preserves source column names and independent number domains.
SPECS = {
    'Powerball': [('powerball', ['White', 'Powerball', 'Powerplay'], [(5, 1, 69, True), (1, 1, 26, False), (1, 2, 10, False)]),
                  ('double-play', ['Double Play White', 'Double Play Powerball'], [(5, 1, 69, True), (1, 1, 26, False)])],
    'Mega Millions': [('mega-millions', ['Mega Millions White', 'Megaball'], [(5, 1, 70, True), (1, 1, 24, False)])],
    'Pick 5': [('pick-5', ['Pick 5 White'], [(5, 1, 40, True)])],
    'Lotto America': [('lotto-america', ['Red', 'Star Ball', 'All Star Bonus'], [(5, 1, 52, True), (1, 1, 10, False), (1, 2, 5, False)])],
    'Millionaire for Life': [('millionaire-for-life', ['White', 'Millionaire Ball'], [(5, 1, 58, True), (1, 1, 5, False)])],
    'Pick 3': [('pick-3', ['White'], [(3, 0, 9, False)])],
    'Pick 4': [('pick-4', ['Numbers'], [(4, 0, 9, False)])],
    '2by2': [('2by2', ['Red', 'White'], [(2, 1, 26, True), (2, 1, 26, True)])],
    'MyDaY': [('myday', ['Month', 'Day', 'Year'], [(1, 1, 12, False), (1, 1, 31, False), (1, 0, 99, False)])],
    'Powerball Xs and Os': [('xs-and-os', ['Powerball Xs & Os White'], None)],
}
TEAMS = set('ARI ATL BAL BUF CAR CHI CIN CLE DAL DEN DET GB HOU IND JAX KC LAC LAR LV MIA MIN NE NO NYG NYJ PHI PIT SEA SF TB TEN WAS'.split())


def plain(node):
    return ' '.join(node.text_content().split())


def parse_results(raw, family, *, today):
    """Validate every displayed row, return only two latest per observed group.

    `today` is the caller's America/Chicago calendar date. Date-only source values
    remain local dates, with no invented UTC time or prize/winner attachment.
    """
    if family not in SPECS or type(today) is not date:
        raise ValueError('Unknown family or invalid local date')
    tree = html.fromstring(raw)
    headings = [plain(h) for h in tree.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," ld_left ")]/h2')]
    expected = 'Powerball Xs & Os' if family == 'Powerball Xs and Os' else 'Nebraska ' + family
    if headings != [expected]:
        raise ValueError('Family heading mismatch')
    tables = []
    for table in tree.xpath('//table'):
        rows = [[plain(c) for c in r.xpath('./th|./td')] for r in table.xpath('.//tr')]
        if rows and rows[0] and rows[0][0] == 'Date':
            tables.append((table, rows))
    specs = SPECS[family]
    if len(tables) != len(specs):
        raise ValueError('Missing or extra result group')
    result = []
    for (table, rows), (group, columns, domains) in zip(tables, specs):
        if rows[0] != ['Date'] + columns or not 2 <= len(rows) - 1 <= 7:
            raise ValueError('Changed result columns or window')
        parsed = []
        previous = None
        for row in rows[1:]:
            if len(row) != len(columns) + 1 or not re.fullmatch(r'\d{2}/\d{2}/\d{4}', row[0]):
                raise ValueError('Malformed result row')
            drawn = datetime.strptime(row[0], '%m/%d/%Y').date()
            if drawn > today or (previous is not None and drawn >= previous):
                raise ValueError('Future, duplicate or unordered draw')
            previous = drawn
            weekdays = {'Powerball': {0, 2, 5}, 'Mega Millions': {1, 4}, 'Lotto America': {0, 2, 5}, 'Powerball Xs and Os': {6}}
            if family in weekdays and drawn.weekday() not in weekdays[family]:
                raise ValueError('Unexpected drawing weekday')
            fields = []
            if domains is None:
                # The HTML contains adjacent team text nodes; read their individual
                # labels to avoid ambiguous splitting (e.g. NE and NYG).
                source_row = table.xpath('.//tr')[len(parsed) + 1]
                cell = source_row.xpath('./td')[1]
                teams = [s.strip() for s in cell.itertext() if s.strip()]
                if len(teams) != 8 or len(set(teams)) != 8 or not set(teams) <= TEAMS:
                    raise ValueError('Invalid team result')
                fields.append({'label': columns[0], 'values': teams})
            else:
                for label, literal, (size, low, high, unique) in zip(columns, row[1:], domains):
                    if not re.fullmatch(r'\d{1,2}(?:,\s*\d{1,2})*', literal):
                        raise ValueError('Malformed number field')
                    values = [int(s.strip()) for s in literal.split(',')]
                    if len(values) != size or any(v < low or v > high for v in values) or (unique and len(set(values)) != size):
                        raise ValueError('Invalid number domain')
                    if label == 'Powerplay' and values[0] not in {2, 3, 4, 5, 10}:
                        raise ValueError('Invalid Power Play multiplier')
                    fields.append({'label': label, 'values': values, 'sourceText': literal})
                if family == 'MyDaY':
                    month, day, year = [f['values'][0] for f in fields]
                    date(2000 + year, month, day)  # Source permits Feb29 for year00.
            parsed.append({'family': family, 'group': group, 'drawDate': drawn.isoformat(),
                           'dateZone': 'America/Chicago', 'fields': fields,
                           'sourceUrl': 'https://nelottery.com/lotto-detail?gamename=' + quote_plus(family)})
        result.extend(parsed[:2])
    return result
