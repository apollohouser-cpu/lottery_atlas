"""Strict daily Arizona lotto DOM evidence; no prize-count inference."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

CONTRACTS = {'fantasy-5': (5, 41), 'triple-twist': (6, 42)}


def parse_capture(capture, game):
    if game not in CONTRACTS:
        raise ValueError('unsupported daily game')
    count, maximum = CONTRACTS[game]
    source = f'https://www.arizonalottery.com/draw-games/{game}/'
    if capture.get('sourceUrl') != source or capture.get('captureKind') != 'browser-dom-table-observation':
        raise ValueError('source/provenance mismatch')
    acquired = datetime.fromisoformat(capture['retrievedAt'].replace('Z', '+00:00'))
    if acquired.tzinfo is None:
        raise ValueError('acquisition timezone required')
    today = acquired.astimezone(ZoneInfo('America/Phoenix')).date()
    tables = capture.get('tables', [])
    if len(tables) != 1:
        raise ValueError('exactly one result table required')
    rows = [[c['text'] for c in row] for row in tables[0]['rows']]
    if not rows or rows[0] != ['Draw Date', 'Winning Numbers', 'Prize Details']:
        raise ValueError('result headers changed')
    if rows[-1] != ['SEE MORE Download as a PDF']:
        raise ValueError('missing footer')
    body = rows[1:-1]
    if len(body) < 4 or len(body) % 2:
        raise ValueError('incomplete result pairs')
    results = []
    previous = None
    for i in range(0, len(body), 2):
        row, detail = body[i:i+2]
        if len(row) != 3 or row[-1] != 'Prizes' or len(detail) != 1 or not detail[0].startswith('$'):
            raise ValueError('result/detail structure changed')
        if not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}', row[0]):
            raise ValueError('invalid date')
        day = datetime.strptime(row[0], '%m/%d/%Y').date()
        if day > today or (previous and previous - day != timedelta(days=1)):
            raise ValueError('future, missing, duplicate or unordered daily result')
        previous = day
        if not re.fullmatch(r'\d{1,2}( \d{1,2}){' + str(count - 1) + '}', row[1]):
            raise ValueError('invalid numbers')
        numbers = list(map(int, row[1].split()))
        if len(set(numbers)) != count or not all(1 <= n <= maximum for n in numbers):
            raise ValueError('invalid number range or duplicates')
        results.append(dict(game=game, drawDate=day.isoformat(),
                            numbers=numbers, sourceUrl=source,
                            reportStatus='unavailable'))
    return results
