"""Strict bounded Iowa numeric results. No counts, jackpots or inferred timestamps."""
from datetime import datetime, date
import re
from lxml import html

# Page/table identity is part of the source contract, including duplicate PB IDs.
SPECS = {
 'powerball': ('PowerballWin', 'colorPB', 'WinningNumbersGridPB1_', 5, 69, 26, (2,3,4,5,10)),
 'double_play': ('PowerballWin', 'colorPB', 'WinningNumbersGridDP1_', 5, 69, 26, ()),
 'mega_millions': ('MegaMillionsWin', 'colorMM', None, 5, 70, 24, ()),
 'lotto_america': ('LottoAmericaWin', 'colorLA', 'WinningNumbersGridLA1_', 5, 52, 10, (2,3,4,5)),
 'millionaire_for_life': ('MillionaireForLifeWin', 'color', None, 5, 58, 5, ()),
 'pick3_midday': ('Pick3MWin', 'color', None, 3, 9, None, ()),
 'pick3_evening': ('Pick3Win', 'color', None, 3, 9, None, ()),
 'pick4_midday': ('Pick4MWin', 'color', None, 4, 9, None, ()),
 'pick4_evening': ('Pick4Win', 'color', None, 4, 9, None, ()),
}

def plain(e):
    return ' '.join(' '.join(e.itertext()).split())

def parse_results(raw, group, *, as_of):
    """Return exactly two newest rows after validating the complete visible table.

    Caller supplies today's America/Chicago date. XsOs needs a separate reviewed
    image-to-team contract and deliberately is not accepted by this parser.
    """
    if type(as_of) is not date:
        raise ValueError('Explicit local as_of date required')
    if group not in SPECS:
        raise ValueError('Unsupported group')
    page, table_id, marker, length, maximum, special_max, multipliers = SPECS[group]
    tree = html.fromstring(raw)
    tables = tree.xpath('//table[@id=$id]', id=table_id)
    if marker:
        tables = [t for t in tables if t.xpath('.//span[contains(@id,$marker)]', marker=marker)]
    if len(tables) != 1:
        raise ValueError('Missing or ambiguous result table/variant')
    # Pick sessions share table IDs, so the explicit page/session heading is mandatory.
    if group.startswith('pick'):
        text = plain(tree)
        session = 'Midday' if group.endswith('midday') else 'Evening'
        if not re.search(r'\b'+session+r' Winning Numbers\b', text, re.I):
            raise ValueError('Missing session identity')
    table = tables[0]
    rows = table.xpath('./tr|./tbody/tr|./thead/tr')
    if rows and rows[-1].get('class') == 'footercolor' and not plain(rows[-1]) and len(rows[-1].xpath('./td')) == 1:
        rows = rows[:-1]
    if len(rows) < 3:
        raise ValueError('Insufficient bounded history')
    headers = [plain(c) for c in rows[0].xpath('./th')]
    expected = 'Numbers Power Play' if group == 'powerball' else 'Numbers All Star Bonus' if group == 'lotto_america' else 'Numbers Megaplier' if group == 'mega_millions' else 'Numbers'
    if headers != ['Date', expected]:
        raise ValueError('Unexpected result headers')
    result = []
    for row in rows[1:]:
        cells = row.xpath('./td')
        if len(cells) != 2:
            raise ValueError('Malformed result row')
        if marker and not cells[0].xpath('.//span[contains(@id,$marker)]', marker=marker):
            raise ValueError('Mixed row variant identity')
        raw_date = plain(cells[0])
        if not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}', raw_date):
            raise ValueError('Invalid date spelling')
        day = datetime.strptime(raw_date, '%m/%d/%Y').date()
        if day > as_of or day < date(2026, 2, 22):
            raise ValueError('Future or unsupported historical rules')
        if result and day.isoformat() >= result[-1]['drawDate']:
            raise ValueError('Duplicate or unordered dates')
        text = plain(cells[1])
        count = length + (1 if special_max else 0)
        pattern = r'(\d{1,2}(?:\s*-\s*\d{1,2}){'+str(count-1)+r'})'
        if multipliers:
            pattern += r'\s+(\d+)'
        match = re.fullmatch(pattern, text)
        if not match:
            raise ValueError('Invalid numbers or unexpected multiplier')
        tokens = re.split(r'\s*-\s*', match[1])
        numbers = [int(x) for x in tokens[:length]]
        minimum = 1 if special_max else 0
        if any(not minimum <= n <= maximum for n in numbers):
            raise ValueError('Number outside game range')
        if special_max and (len(set(numbers)) != length or numbers != sorted(numbers)):
            raise ValueError('Duplicate or unsorted main balls')
        if not special_max and any(len(x) != 1 for x in tokens):
            raise ValueError('Pick digits must be literal single digits')
        item = dict(group=group, drawDate=day.isoformat(), sourceDateText=raw_date,
                    numbers=numbers, sourceUrl='https://www.ialottery.com/Pages/Games-Online/'+page+'.aspx')
        if special_max:
            special = int(tokens[-1])
            if not 1 <= special <= special_max:
                raise ValueError('Special ball outside range')
            item['specialBall'] = special
        if multipliers:
            multiplier = int(match[2])
            if multiplier not in multipliers:
                raise ValueError('Invalid multiplier')
            item['multiplier'] = multiplier
        result.append(item)
    return result[:2]
