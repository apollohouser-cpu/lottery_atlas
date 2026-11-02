"""Parse explicit Pick 3 date/session labels and preserve ordered digits."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/draw-games/pick-3/'


def parse_capture(capture):
    if capture.get('sourceUrl') != SOURCE or capture.get('captureKind') != 'browser-dom-table-observation':
        raise ValueError('source/provenance mismatch')
    acquired = datetime.fromisoformat(capture['retrievedAt'].replace('Z', '+00:00'))
    if acquired.tzinfo is None:
        raise ValueError('timezone required')
    today = acquired.astimezone(ZoneInfo('America/Phoenix')).date()
    tables = capture.get('tables', [])
    if len(tables) != 1:
        raise ValueError('one result table required')
    rows = [[c['text'] for c in r] for r in tables[0]['rows']]
    if not rows or rows[0] != ['Draw Date', 'Winning Numbers', 'Prize Details'] or rows[-1] != ['SEE MORE']:
        raise ValueError('headers/footer changed')
    body = rows[1:-1]
    if len(body) % 2:
        raise ValueError('incomplete result pairs')
    groups = {'pick-3-midday': [], 'pick-3-evening': []}
    previous = None
    for i in range(0, len(body), 2):
        row, detail = body[i:i+2]
        if len(row) != 3 or row[-1] != 'Prizes' or len(detail) != 1 or not detail[0].startswith('Straight\tBox\tCombined Box\tFront Pair\tBack Pair'):
            raise ValueError('result structure changed')
        match = re.fullmatch(r'(\d{1,2}/\d{1,2}/\d{4}) (Midday|Evening)', row[0])
        if not match or not re.fullmatch(r'[0-9] [0-9] [0-9]', row[1]):
            raise ValueError('explicit session and three ordered digits required')
        day = datetime.strptime(match[1], '%m/%d/%Y').date()
        session = match[2].lower()
        identity = (day, 1 if session == 'evening' else 0)
        if day < datetime(2026, 6, 14).date() or day > today or (previous and identity >= previous):
            raise ValueError('date/format/order mismatch')
        if previous:
            expected = (previous[0], 0) if previous[1] else (previous[0] - timedelta(days=1), 1)
            if identity != expected:
                raise ValueError('missing session')
        previous = identity
        game = 'pick-3-' + session
        groups[game].append(dict(game=game, drawDate=day.isoformat(), session=session,
                                 digits=row[1].replace(' ', ''), sourceUrl=SOURCE,
                                 reportStatus='unavailable'))
    if any(len(g) < 2 for g in groups.values()):
        raise ValueError('two results per session required')
    return groups
