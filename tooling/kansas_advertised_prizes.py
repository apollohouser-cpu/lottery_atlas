"""Bounded advertised jackpot metadata, separate from draws and paid prizes."""
from datetime import datetime
import re

from tooling.kansas_draw_results import CENTRAL, integer

# Only these source fields have unambiguous jackpot/cash labels in the current
# game rules. Lifetime and fixed-prize products keep their literal schedules.
GAMES = {
    1: ('powerball', 'powerball', True),
    3: ('lotto_america', 'lotto-america', True),
    8: ('kansas_cash', 'super-kansas-cash', False),
    12: ('mega_millions', 'megamillions', True),
}


def parse_advertised_prizes(rows, retrieved_at):
    if not isinstance(rows, list):
        raise ValueError('Missing advertised game metadata')
    retrieval = datetime.fromisoformat(retrieved_at.replace('Z', '+00:00'))
    if retrieval.tzinfo is None:
        raise ValueError('Retrieval requires timezone')
    selected = {}
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError('Invalid game metadata row')
        game_id = integer(row.get('gameId'), 1)
        if game_id not in GAMES:
            continue
        key, slug, annuity = GAMES[game_id]
        if game_id in selected or row.get('gameKey') != key:
            raise ValueError('Duplicate or conflicting advertised game identity')
        raw = row.get('nextDrawDate')
        if not isinstance(raw, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', raw):
            raise ValueError('Missing advertised draw timestamp')
        timestamp = datetime.fromisoformat(raw.replace('Z', '+00:00'))
        if row.get('nextDrawingDate') != timestamp.date().isoformat():
            raise ValueError('Unexpected advertised date convention')
        cash = integer(row.get('nextCashAmount'), 1)
        advertised_annuity = integer(row.get('nextAnnuityAmount'), 1 if annuity else 0)
        if not annuity and advertised_annuity != 0:
            raise ValueError('Unexpected annuity on cash-only game')
        selected[game_id] = {
            'scheduleKey': slug,
            'sourceUrl': f'https://playonkansas.com/games/draw-games/{slug}',
            'sourceDrawTimestamp': raw,
            'sourceDrawingDate': row['nextDrawingDate'],
            'drawDate': timestamp.astimezone(CENTRAL).date().isoformat(),
            'drawTimeZone': 'America/Chicago',
            'advertisedAnnuityDollars': advertised_annuity if annuity else None,
            'advertisedCashDollars': cash,
            'sourceDrawTimeHasPassed': timestamp <= retrieval,
            'coverage': 'Source-advertised amounts for the identified drawing, not actual paid prizes. Cash value is directly supplied, not converted.',
            'sourceWarnings': ['Source nextDrawingDate uses UTC; local date is derived from its timestamp. A passed source draw time must not be labeled upcoming.'],
        }
    if set(selected) != set(GAMES):
        raise ValueError('Missing advertised jackpot family')
    return [selected[key] for key in sorted(selected)]
