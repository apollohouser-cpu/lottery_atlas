"""Strict Lucky Links DOM results; ticket positions and counts are not inferred."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/quick-draw/lucky-links/'


def parse_capture(capture):
    minute, prize_header = '00', 'Prizes'
    detail_header = '2 Lines ($2)\t3 Lines ($7)\t4 Lines ($25)\t5 Lines ($50)\t6 Lines ($500)\t7-8 Lines ($25,000)'
    tiers = 6
    game = 'lucky-links'
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
    if rows[0] != ['Draw ID', 'Drawing Time', 'Winning Numbers', 'Super Bonus', prize_header] or rows[-1] not in ([''], ['SEE MORE']):
        raise ValueError('table boundary changed')
    body = rows[1:-1]
    if len(body) % 2 or not 2 <= len(body) <= 38:
        raise ValueError('one to nineteen hourly rows required')
    results = []
    previous = None
    previous_id = None
    for i in range(0, len(body), 2):
        row, detail = body[i:i+2]
        if len(detail) != 1 or not re.fullmatch(re.escape(detail_header) + r'\n\d+' + r'\t\d+' * (tiers - 1), detail[0]):
            raise ValueError('prize detail structure changed')
        if len(row) != 5 or not re.fullmatch(r'[1-9]\d*', row[0]) or not re.fullmatch(r'\d{1,2}:' + minute + r' [AP]M', row[1]):
            raise ValueError('invalid draw identity/time')
        instant = datetime.strptime(day + ' ' + row[1], '%Y-%m-%d %I:%M %p').replace(tzinfo=ZoneInfo('America/Phoenix'))
        draw_id = int(row[0])
        if not 5 <= instant.hour <= 23 or instant > acquired or (previous and previous-instant != timedelta(hours=1)) or (previous_id and previous_id-draw_id != 1):
            raise ValueError('future, out-of-schedule or discontinuous draw')
        if not re.fullmatch(r'[0-9]{2}' + r' [0-9]{2}' * 7, row[2]):
            raise ValueError('eight literal numbers required')
        numbers = [int(n) for n in row[2].split()]
        if len(set(numbers)) != 8 or any(not 1 <= n <= 22 for n in numbers):
            raise ValueError('invalid or duplicate winning numbers')
        if row[3] not in ('1x', '2x', '3x', '4x', '5x') or row[4] != 'Prizes':
            raise ValueError('invalid bonus or action')
        results.append(dict(game=game, drawId=row[0], drawDate=day,
                            drawTime=row[1], timeZone='America/Phoenix',
                            superBonus=int(row[3][0]),
                            sourceUrl=source, reportStatus='unavailable'))
        results[-1]['numbers'] = numbers
        previous, previous_id = instant, draw_id
    return results
