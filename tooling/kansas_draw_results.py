"""Strict Kansas public results. Unverified share counts never enter app output."""
from datetime import datetime
import re
from zoneinfo import ZoneInfo

CENTRAL = ZoneInfo('America/Chicago')
GROUPS = {
    'pick3-midday': (9, 'Pick 3', 'Midday', 'pick-3', 3, 9, None),
    'pick3-evening': (10, 'Pick 3', 'Evening', 'pick-3', 3, 9, None),
    'super-kansas-cash': (8, 'Super Kansas Cash', 'Drawing', 'super-kansas-cash', 5, 32, 25),
}


def integer(value, minimum=0):
    if type(value) is not int or value < minimum:
        raise ValueError('Invalid source integer')
    return value


def parse_results(payload, group, retrieved_at):
    """Validate every supplied row before bounding the newest two results."""
    game_id, family, session, slug, normal_count, maximum, special_max = GROUPS[group]
    retrieval = datetime.fromisoformat(retrieved_at.replace('Z', '+00:00'))
    if retrieval.tzinfo is None:
        raise ValueError('Retrieval must have timezone')
    if not isinstance(payload, dict) or not isinstance(payload.get('content'), list):
        raise ValueError('Missing result page')
    rows = payload['content']
    if len(rows) < 2 or integer(payload.get('numberOfElements')) != len(rows):
        raise ValueError('Incomplete result page')
    if integer(payload.get('number')) != 0 or payload.get('first') is not True:
        raise ValueError('Expected latest page')
    if integer(payload.get('totalElements')) < len(rows) or integer(payload.get('size'), 1) < len(rows):
        raise ValueError('Invalid page counts')
    result, ids, draws, dates = [], set(), set(), set()
    previous = None
    for row in rows:
        if not isinstance(row, dict) or type(row.get('gameId')) is not int or row['gameId'] != game_id:
            raise ValueError('Wrong source game/session')
        if row.get('jackpotStatus') != 'COMPLETE' or row.get('isDoublePlayResult') is not False:
            raise ValueError('Wrong completion/variant')
        rid = integer(row.get('id'), 1)
        draw_number = row.get('externalId')
        if not isinstance(draw_number, str) or not re.fullmatch(r'[1-9]\d*', draw_number):
            raise ValueError('Invalid draw number')
        raw_time = row.get('drawDate')
        if not isinstance(raw_time, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', raw_time):
            raise ValueError('Invalid UTC draw timestamp')
        timestamp = datetime.fromisoformat(raw_time.replace('Z', '+00:00'))
        if timestamp > retrieval or (previous is not None and timestamp >= previous):
            raise ValueError('Future or unordered result')
        previous = timestamp
        local = timestamp.astimezone(CENTRAL)
        local_date = local.date().isoformat()
        if row.get('drawingDate') != timestamp.date().isoformat():
            raise ValueError('Unexpected raw date convention')
        if (session == 'Midday' and not 11 <= local.hour <= 15) or (session != 'Midday' and not 20 <= local.hour <= 23):
            raise ValueError('Draw timestamp does not match session')
        if rid in ids or draw_number in draws or local_date in dates:
            raise ValueError('Duplicate result identity/date')
        ids.add(rid); draws.add(draw_number); dates.add(local_date)
        numbers = row.get('resultData')
        expected = normal_count + (special_max is not None)
        if not isinstance(numbers, list) or len(numbers) != expected:
            raise ValueError('Invalid number count')
        normal, special = [], []
        for i, cell in enumerate(numbers):
            if not isinstance(cell, dict) or type(cell.get('order')) is not int or cell['order'] != i or type(cell.get('resultId')) is not int or cell['resultId'] != rid:
                raise ValueError('Broken result association/order')
            is_special = i >= normal_count
            if cell.get('type') != ('SPECIAL' if is_special else 'NORMAL'):
                raise ValueError('Wrong number group')
            value = integer(cell.get('data'), 0 if family == 'Pick 3' else 1)
            if value > (special_max if is_special else maximum):
                raise ValueError('Number out of range')
            (special if is_special else normal).append(str(value))
        if family != 'Pick 3' and len(set(normal)) != normal_count:
            raise ValueError('Duplicate normal balls')
        if row.get('multiplier') is not None:
            raise ValueError('Unsupported multiplier')
        warnings = []
        if local_date != row['drawingDate']:
            warnings.append('Source drawingDate uses the UTC date; local draw date is derived in America/Chicago from the preserved timestamp.')
        result.append({
            'id': f'{group}:{draw_number}', 'family': family, 'group': group,
            'session': session, 'drawNumber': draw_number,
            'sourceDrawTimestamp': raw_time, 'sourceDrawingDate': row['drawingDate'],
            'drawDate': local_date, 'drawTimeZone': 'America/Chicago',
            'numbers': normal, 'specialNumbers': special, 'sourceWarnings': warnings,
            'sourceUrl': f'https://playonkansas.com/games/draw-games/{slug}',
            'coverage': 'Drawn numbers only. Kansas winner counts and actual payouts are not established by this source; prize schedules are separate.',
        })
    return result[:2]
