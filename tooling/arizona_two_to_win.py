"""Strict hourly positional-game DOM results; source counts are not promoted."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/quick-draw/two-to-win/'


def parse_capture(capture, game='two-to-win'):
    contracts = {
        'money-roll': (5, '50', 'Prizes*', '2 Matches ($1)\t3 Matches ($5)\t4 Matches ($55)\t5 Matches ($1,000)', 4),
        'two-to-win': (2, '20', 'Prizes*', 'Back Digit ($6)\tFront Digit ($6)\tBox ($30)\tStraight ($60)', 4),
        '5-in-a-line': (5, '30', 'Prizes', 'First Digit ($2)\tFirst 2 Digits ($20)\tFirst 3 Digits ($200)\tFirst 4 Digits ($500)\tAll 5 Digits ($5,000)', 5),
    }
    if game not in contracts:
        raise ValueError('unsupported hourly digit game')
    width, minute, prize_header, detail_header, tiers = contracts[game]
    source = f'https://www.arizonalottery.com/quick-draw/{game}/'
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
    if rows[0] != ['Draw ID', 'Drawing Time', 'Winning Numbers', 'Super Bonus', prize_header] or rows[-1] != ['']:
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
        valid_numbers = (len(row[2].split('\n')) == 5 and set(row[2].split('\n')) <= {'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX'}) if game == 'money-roll' else bool(re.fullmatch(r'[0-9]' + r' [0-9]' * (width - 1), row[2]))
        if not valid_numbers or row[3] not in ('1x', '2x', '3x', '4x', '5x') or row[4] != 'Prizes':
            raise ValueError('invalid digits, bonus or action')
        results.append(dict(game=game, drawId=row[0], drawDate=day,
                            drawTime=row[1], timeZone='America/Phoenix',
                            superBonus=int(row[3][0]),
                            sourceUrl=source, reportStatus='unavailable'))
        if game == 'money-roll':
            results[-1]['diceLabels'] = row[2].split('\n')
        else:
            results[-1]['digits'] = row[2].replace(' ', '')
        previous, previous_id = instant, draw_id
    return results
