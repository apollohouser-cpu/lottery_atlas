"""Literal observed Xs & Os team abbreviations; no inferred roster mapping."""
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

SOURCE = 'https://www.arizonalottery.com/draw-games/powerball-xs-os/'
# Observed labels only. An unseen label requires review, not guessed expansion.
OBSERVED_LABELS = frozenset('ARI ATL BAL CAR CHI CIN CLE DAL DEN DET GB HOU JAX KC LAC LV MIA MIN NE NO NYG PHI PIT SEA SF TB TEN WAS'.split())


def parse_capture(capture):
    if capture.get('sourceUrl') != SOURCE or capture.get('captureKind') != 'browser-dom-table-observation':
        raise ValueError('source/provenance mismatch')
    acquired = datetime.fromisoformat(capture['retrievedAt'].replace('Z', '+00:00'))
    if acquired.tzinfo is None:
        raise ValueError('timezone required')
    tables = capture['tables']
    if len(tables) != 1:
        raise ValueError('one result table required')
    rows = tables[0]['rows']
    if [c['text'] for c in rows[0]] != ['Draw Date', 'Winning Draw Results', 'Prize Details'] or [c['text'] for c in rows[-1]] != ['Download as a PDF']:
        raise ValueError('table boundary changed')
    body = rows[1:-1]
    if len(body) < 4 or len(body) % 2:
        raise ValueError('incomplete result pairs')
    results = []
    previous = None
    for i in range(0, len(body), 2):
        row, detail = body[i:i+2]
        if len(row) != 3 or row[2]['text'] != 'Prizes*' or len(detail) != 1 or detail[0]['text'].split('\n')[0] != 'MATCH 4\tMATCH 5\tMATCH 6\tMATCH 7\tJACKPOT':
            raise ValueError('result structure changed')
        day = datetime.strptime(row[0]['text'], '%m/%d/%Y').date()
        if day > acquired.astimezone(ZoneInfo('America/Phoenix')).date() or day.weekday() != 6 or (previous and previous-day != timedelta(days=7)):
            raise ValueError('draw date/cadence mismatch')
        previous = day
        labels = row[1]['text'].split('\n')
        images = row[1]['images']
        if len(labels) != 8 or len(set(labels)) != 8 or not set(labels) <= OBSERVED_LABELS:
            raise ValueError('unreviewed, missing or duplicate team label')
        if images != [{'alt': label, 'src': '/media/powerball_xo/' + label.lower() + '.svg'} for label in labels]:
            raise ValueError('image/label source join changed')
        results.append(dict(game='powerball-xs-os', drawDate=day.isoformat(),
                            teamLabels=labels, sourceUrl=SOURCE, reportStatus='unavailable'))
    return results
