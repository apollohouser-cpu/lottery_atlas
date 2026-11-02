"""Strict Hi-Lo DOM observations; category totals are not winner counts."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/quick-draw/hi-lo/'


def parse_capture(capture):
    minute, prize_header = '10', 'Prizes*'
    detail_header = '10, 10 ($3)\t9, 11 ($3)\t8, 12 ($5)\t7, 13 ($10)\t6, 14 ($30)\t5, 15 ($115)\t0-4, 16-20 ($555)'
    tiers = 7
    game = 'hi-lo'
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
    if rows[0] != ['Draw ID', 'Drawing Time', 'Winning Information', 'Super Bonus', prize_header] or rows[-1] not in ([''], ['SEE MORE']):
        raise ValueError('table boundary changed')
    body = rows[1:-1]
    if len(body) % 2 or not 4 <= len(body) <= 40:
        raise ValueError('two to twenty hourly rows required')
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
        if not 4 <= instant.hour <= 23 or instant > acquired or (previous and previous-instant != timedelta(hours=1)) or (previous_id and previous_id-draw_id != 1):
            raise ValueError('future, out-of-schedule or discontinuous draw')
        match = re.fullmatch(r'Hi - (0|[1-9]|1[0-9]|20) \| Lo - (0|[1-9]|1[0-9]|20)', row[2])
        if not match or row[3] not in ('1x', '2x', '3x', '4x', '5x') or row[4] != 'Prizes':
            raise ValueError('invalid winning information, bonus or action')
        high, low = map(int, match.groups())
        if high + low != 20:
            raise ValueError('Hi-Lo totals must sum to twenty')
        results.append(dict(game=game, drawId=row[0], drawDate=day,
                            drawTime=row[1], timeZone='America/Phoenix',
                            superBonus=int(row[3][0]),
                            sourceUrl=source, reportStatus='unavailable'))
        results[-1].update(highNumberTotal=high, lowNumberTotal=low)
        previous, previous_id = instant, draw_id
    return results
