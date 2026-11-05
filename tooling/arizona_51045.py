"""Strict 5/10/45 DOM observations; $1 wager units are not ticket counts."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/quick-draw/51045/'


def parse_capture(capture):
    minute = '15'
    detail_header = '5 of 5\t4 of 5\t3 of 5\t0 of 5\t4 of 4\t3 of 4\t2 of 4\t3 of 3\t2 of 3\t2 of 2\t1 of 2\t1 of 1\tBullseye Wins'
    tiers = 13
    game = '51045'
    source = SOURCE
    if capture.get('sourceUrl') != source or capture.get('captureKind') != 'browser-dom-table-observation':
        raise ValueError('source/provenance mismatch')
    acquired = datetime.fromisoformat(capture['retrievedAt'].replace('Z', '+00:00'))
    if acquired.tzinfo is None:
        raise ValueError('retrieval timezone required')
    day = capture['selectedDate']
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', day):
        raise ValueError('selected date required')
    datetime.strptime(day, '%Y-%m-%d')
    tables = capture['tables']
    if len(tables) != 1:
        raise ValueError('one result table required')
    rows = [[cell['text'] for cell in row] for row in tables[0]['rows']]
    if rows[0] != ['Draw ID', 'Drawing Time', 'Winning Numbers', 'Bullseye', 'Super Bonus', ''] or rows[-1] not in ([''], ['SEE MORE']):
        raise ValueError('table boundary changed')
    body = rows[1:-1]
    if len(body) % 2 or not 2 <= len(body) <= 40:
        raise ValueError('one to twenty hourly rows required')
    results = []
    previous = None
    previous_id = None
    for i in range(0, len(body), 2):
        row, detail = body[i:i+2]
        if len(detail) != 1 or not re.fullmatch(re.escape(detail_header) + r'\n\d+' + r'\t\d+' * (tiers - 1), detail[0]):
            raise ValueError('prize detail structure changed')
        if len(row) != 6 or not re.fullmatch(r'[1-9]\d*', row[0]) or not re.fullmatch(r'\d{1,2}:' + minute + r' [AP]M', row[1]):
            raise ValueError('invalid draw identity/time')
        instant = datetime.strptime(day + ' ' + row[1], '%Y-%m-%d %I:%M %p').replace(tzinfo=ZoneInfo('America/Phoenix'))
        draw_id = int(row[0])
        if not 4 <= instant.hour <= 23 or instant > acquired or (previous and previous-instant != timedelta(hours=1)) or (previous_id and previous_id-draw_id != 1):
            raise ValueError('future, out-of-schedule or discontinuous draw')
        if not re.fullmatch(r'[0-9]{2}' + r' [0-9]{2}' * 9, row[2]):
            raise ValueError('ten literal numbers required')
        numbers = [int(n) for n in row[2].split()]
        if len(set(numbers)) != 10 or any(not 1 <= n <= 45 for n in numbers):
            raise ValueError('invalid or duplicate winning numbers')
        if not re.fullmatch(r'[0-9]{2}', row[3]) or int(row[3]) not in numbers:
            raise ValueError('Bullseye must belong to winning numbers')
        if row[4] not in ('2x', '3x', '4x', '5x', '6x', '10x', '12x', '20x') or row[5] != 'Prizes':
            raise ValueError('invalid bonus or action')
        results.append(dict(game=game, drawId=row[0], drawDate=day,
                            drawTime=row[1], timeZone='America/Phoenix',
                            superBonus=int(row[4][:-1]),
                            sourceUrl=source, reportStatus='unavailable'))
        results[-1].update(numbers=numbers, bullseye=int(row[3]))
        previous, previous_id = instant, draw_id
    return results
