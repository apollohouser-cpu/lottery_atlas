"""Dated hourly One To Win DOM results; reported wager units are not tickets."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/quick-draw/one-to-win/'


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
    if rows[0] != ['Draw ID', 'Drawing Time', 'Base Prize Amount*', 'Winning Number', 'Number of Wins**'] or rows[-1] != ['']:
        raise ValueError('table boundary changed')
    if not 2 <= len(rows[1:-1]) <= 20:
        raise ValueError('two to twenty hourly rows required')
    results = []
    previous = None
    previous_id = None
    for row in rows[1:-1]:
        if len(row) != 5 or not re.fullmatch(r'[1-9]\d*', row[0]) or not re.fullmatch(r'\d{1,2}:45 [AP]M', row[1]):
            raise ValueError('invalid draw identity/time')
        instant = datetime.strptime(day + ' ' + row[1], '%Y-%m-%d %I:%M %p').replace(tzinfo=ZoneInfo('America/Phoenix'))
        draw_id = int(row[0])
        if not 4 <= instant.hour <= 23 or instant > acquired or (previous and previous-instant != timedelta(hours=1)) or (previous_id and previous_id-draw_id != 1):
            raise ValueError('future, out-of-schedule or discontinuous draw')
        if row[2] not in ('$5', '$7', '$10', '$20', '$50', '$100', '$250'):
            raise ValueError('unreviewed base prize')
        if not re.fullmatch(r'\d{2}', row[3]) or not 1 <= int(row[3]) <= 15 or not re.fullmatch(r'\d+', row[4]):
            raise ValueError('invalid number or source win units')
        results.append(dict(game='one-to-win', drawId=row[0], drawDate=day,
                            drawTime=row[1], timeZone='America/Phoenix',
                            number=int(row[3]), basePrizeAmount=row[2],
                            sourceUrl=SOURCE, reportStatus='unavailable'))
        previous, previous_id = instant, draw_id
    return results
