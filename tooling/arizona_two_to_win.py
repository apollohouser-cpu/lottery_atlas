"""Dated hourly Two To Win DOM results; reported wager units are not tickets."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/quick-draw/two-to-win/'


def parse_capture(capture):
    if capture.get('sourceUrl') != SOURCE or capture.get('captureKind') != 'browser-dom-table-observation':
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
    if rows[0] != ['Draw ID', 'Drawing Time', 'Winning Numbers', 'Super Bonus', 'Prizes*'] or rows[-1] != ['']:
        raise ValueError('table boundary changed')
    body = rows[1:-1]
    if len(body) % 2 or not 4 <= len(body) <= 40:
        raise ValueError('two to twenty hourly rows required')
    results = []
    previous = None
    previous_id = None
    for i in range(0, len(body), 2):
        row, detail = body[i:i+2]
        if len(detail) != 1 or not re.fullmatch(r'Back Digit \(\$6\)\tFront Digit \(\$6\)\tBox \(\$30\)\tStraight \(\$60\)\n\d+\t\d+\t\d+\t\d+', detail[0]):
            raise ValueError('prize detail structure changed')
        if len(row) != 5 or not re.fullmatch(r'[1-9]\d*', row[0]) or not re.fullmatch(r'\d{1,2}:20 [AP]M', row[1]):
            raise ValueError('invalid draw identity/time')
        instant = datetime.strptime(day + ' ' + row[1], '%Y-%m-%d %I:%M %p').replace(tzinfo=ZoneInfo('America/Phoenix'))
        draw_id = int(row[0])
        if not 4 <= instant.hour <= 23 or instant > acquired or (previous and previous-instant != timedelta(hours=1)) or (previous_id and previous_id-draw_id != 1):
            raise ValueError('future, out-of-schedule or discontinuous draw')
        if not re.fullmatch(r'[0-9] [0-9]', row[2]) or row[3] not in ('1x', '2x', '3x', '4x', '5x') or row[4] != 'Prizes':
            raise ValueError('invalid digits, bonus or action')
        results.append(dict(game='two-to-win', drawId=row[0], drawDate=day,
                            drawTime=row[1], timeZone='America/Phoenix',
                            digits=row[2].replace(' ', ''), superBonus=int(row[3][0]),
                            sourceUrl=SOURCE, reportStatus='unavailable'))
        previous, previous_id = instant, draw_id
    return results
