"""Parse observed Arizona PB/Double Play DOM tables, never prize counts.

This is an evidence parser, not an HTTP collector or publication pipeline.
"""
import re
from datetime import datetime
from zoneinfo import ZoneInfo
from tooling.arizona_draw_continuity import select_latest

SOURCE = 'https://www.arizonalottery.com/draw-games/powerball/'
BASE = ['Draw Date', 'Winning Numbers', 'Powerball']
HEADERS = {
    'powerball': BASE + ['Power Play', 'Prize Details'],
    'powerball-double-play': BASE + ['Prize Details'],
}


def parse_capture(capture):
    """Reject incomplete/template tables; retain all observed date-only draws."""
    if capture.get('sourceUrl') != SOURCE or capture.get('captureKind') != 'browser-dom-table-observation':
        raise ValueError('source/provenance mismatch')
    acquired = datetime.fromisoformat(capture['retrievedAt'].replace('Z', '+00:00'))
    if acquired.tzinfo is None:
        raise ValueError('acquisition timezone required')
    today = acquired.astimezone(ZoneInfo('America/Phoenix')).date()
    tables = capture.get('tables', [])
    if len(tables) != 2:
        raise ValueError('both distinct result tables required')
    found = {}
    for table in tables:
        rows = [[cell['text'] for cell in row] for row in table['rows']]
        matches = [key for key, header in HEADERS.items() if rows[0] == header]
        if len(matches) != 1 or matches[0] in found:
            raise ValueError('unknown or duplicate table identity')
        game = matches[0]
        if rows[-1] != ['SEE MORE Download as a PDF']:
            raise ValueError('missing table footer')
        body = rows[1:-1]
        if len(body) < 4 or len(body) % 2:
            raise ValueError('incomplete result/detail pairs')
        results = []
        previous = None
        for i in range(0, len(body), 2):
            row, detail = body[i:i+2]
            if len(row) != len(HEADERS[game]) or row[-1] != 'Prizes':
                raise ValueError('result structure changed')
            if len(detail) != 1 or not detail[0].startswith('$'):
                raise ValueError('detail structure changed')
            if not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}', row[0]):
                raise ValueError('missing or malformed draw date')
            day = datetime.strptime(row[0], '%m/%d/%Y').date()
            if day > today or day.weekday() not in (0, 2, 5) or (previous and day >= previous):
                raise ValueError('future, off-cadence, duplicate or unordered draw')
            previous = day
            if not re.fullmatch(r'\d{1,2}( \d{1,2}){4}', row[1]) or not re.fullmatch(r'\d{1,2}', row[2]):
                raise ValueError('missing or malformed numbers')
            white = list(map(int, row[1].split()))
            red = int(row[2])
            if len(set(white)) != 5 or not all(1 <= n <= 69 for n in white) or not 1 <= red <= 26:
                raise ValueError('invalid number range or duplicates')
            result = dict(game=game, drawDate=day.isoformat(), numbers=white,
                          powerball=red, sourceUrl=SOURCE, reportStatus='unavailable')
            if game == 'powerball':
                if row[3] not in ('2', '3', '4', '5', '10'):
                    raise ValueError('invalid Power Play')
                result['powerPlay'] = int(row[3])
            results.append(result)
        found[game] = results
    return found


def select_refresh(candidate, retained):
    """Return latest two per game only after validating both full captures.

    Corrections require review. A moving source window may drop old history,
    but must retain the previous two selected draws and every overlapping date.
    Callers must keep the old bytes/date when this raises; this function does
    not mutate either input or perform persistence.
    """
    new = parse_capture(candidate)
    old = parse_capture(retained)
    timestamp = lambda c: datetime.fromisoformat(c['retrievedAt'].replace('Z', '+00:00'))
    if timestamp(candidate) < timestamp(retained):
        raise ValueError('acquisition time regressed')
    return select_latest(new, old)
