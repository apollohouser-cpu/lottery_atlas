"""Parse explicit Pick 3/4 date/session labels and preserve ordered digits."""
import re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/draw-games/pick-3/'


def parse_capture(capture, family='pick-3'):
    if family not in ('pick-3', 'pick-4'):
        raise ValueError('unsupported digit game')
    width = 3 if family == 'pick-3' else 4
    source = f'https://www.arizonalottery.com/draw-games/{family}/'
    detail_header = 'Straight\tBox\tCombined Box\tFront Pair\t' + ('Mid Pair\t' if width == 4 else '') + 'Back Pair'
    if capture.get('sourceUrl') != source or capture.get('captureKind') != 'browser-dom-table-observation':
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
    groups = {family + '-midday': [], family + '-evening': []}
    previous = None
    for i in range(0, len(body), 2):
        row, detail = body[i:i+2]
        if len(row) != 3 or row[-1] != 'Prizes' or len(detail) != 1 or detail[0].split('\n')[0] != detail_header:
            raise ValueError('result structure changed')
        match = re.fullmatch(r'(\d{1,2}/\d{1,2}/\d{4}) (Midday|Evening)', row[0])
        if not match or not re.fullmatch(' '.join(['[0-9]'] * width), row[1]):
            raise ValueError('explicit session and exact ordered digits required')
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
        game = family + '-' + session
        groups[game].append(dict(game=game, drawDate=day.isoformat(), session=session,
                                 digits=row[1].replace(' ', ''), sourceUrl=source,
                                 reportStatus='unavailable'))
    if any(len(g) < 2 for g in groups.values()):
        raise ValueError('two results per session required')
    return groups
