"""Strict bounded Wyoming result parsing; no winner-count inference."""
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

MOUNTAIN = ZoneInfo('America/Denver')
# Supported capture window, NOT the inception date of any game or format.
# Earlier records require separate version evidence before import.
SUPPORTED_FROM = datetime(2026, 10, 12, tzinfo=timezone.utc)
CADENCE = {
    'cowboy-draw': ({0, 3}, 14, 0),
    'powerball': ({0, 2, 5}, 20, 59),
    'mega-millions': ({1, 4}, 21, 0),
    'millionaire-for-life': (set(range(7)), 21, 15),
    '2by2': (set(range(7)), 20, 30),
}
SPECS = {
    'cowboy-draw': ('bafaf5b5-8a50-4401-9684-0dbe85b2afb5', 5, 45, 0, 0),
    'powerball': ('acc3110d-907c-413c-8bae-62decf6d4b36', 5, 69, 1, 26),
    'mega-millions': ('710b085b-affd-4145-82cd-90d3e499f869', 5, 70, 1, 24),
    'millionaire-for-life': ('321502b0-5b10-472e-94ff-a199b9eb1f2e', 5, 58, 1, 5),
    '2by2': ('7f2aa0ca-b70e-4373-ba42-0c382300452f', 2, 26, 2, 26),
}


def instant(value):
    if not isinstance(value, str):
        raise ValueError('Missing timestamp')
    try:
        result = datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError as exc:
        raise ValueError('Invalid timestamp') from exc
    if result.tzinfo is None or result.utcoffset().total_seconds() != 0:
        raise ValueError('Expected explicit UTC timestamp')
    return result.astimezone(timezone.utc)


def numbers(value, count, maximum):
    if count == 0:
        if value not in (None, []):
            raise ValueError('Unexpected bonus numbers')
        return []
    if not isinstance(value, list) or len(value) != count:
        raise ValueError('Wrong number count')
    if any(type(n) is not int or not 1 <= n <= maximum for n in value):
        raise ValueError('Invalid number range/type')
    if len(set(value)) != count:
        raise ValueError('Duplicate numbers within group')
    return list(value)


def parse_draws(payload, game, *, start, end, retrieved_at):
    """Validate an explicit query window and retain every completed row in it.

    PENDING rows are excluded only when empty. Unknown statuses and variants fail.
    Caller chooses latest-two after validation; this function never invents dates.
    """
    if game not in SPECS or not isinstance(payload, list) or not payload:
        raise ValueError('Unsupported game or empty response')
    lo, hi, captured = map(instant, (start, end, retrieved_at))
    if lo > hi or hi > captured:
        raise ValueError('Invalid query window')
    gid, count, maximum, bonus_count, bonus_max = SPECS[game]
    output, seen, draw_ids = [], set(), set()
    for row in payload:
        if not isinstance(row, dict):
            raise ValueError('Invalid row')
        when, result = row.get('when', {}), row.get('results', {})
        at = instant(when.get('drawTime'))
        if not lo <= at <= hi or at in seen:
            raise ValueError('Out-of-window or duplicate drawing')
        seen.add(at)
        status = result.get('status')
        if status == 'PENDING':
            if result.get('drawResult') is not None:
                raise ValueError('Pending result contains data')
            continue
        if status != 'ACTIVE':
            raise ValueError('Unknown result status')
        local = at.astimezone(MOUNTAIN)
        days, hour, minute = CADENCE[game]
        if (at < SUPPORTED_FROM or local.weekday() not in days
                or (local.hour, local.minute, local.second, local.microsecond)
                != (hour, minute, 0, 0)):
            raise ValueError('Unsupported version window or drawing cadence')
        raw = result.get('drawResult')
        if not isinstance(raw, dict) or raw.get('drawGameId') != gid:
            raise ValueError('Wrong game identity')
        if instant(raw.get('asOf')) != at:
            raise ValueError('Mismatched result timestamp')
        if raw.get('secondary') is not None or raw.get('sequenceNumber') is not None:
            raise ValueError('Unverified secondary/session result')
        draw_id = raw.get('drawingNumber')
        if type(draw_id) is not int or draw_id <= 0 or draw_id in draw_ids:
            raise ValueError('Invalid or duplicate draw ID')
        draw_ids.add(draw_id)
        primary = raw.get('primary')
        if not isinstance(primary, dict) or set(primary) - {'winningNumbers', 'bonusNumbers', 'multipliers'}:
            raise ValueError('Unknown number structure')
        main = numbers(primary.get('winningNumbers'), count, maximum)
        bonus = numbers(primary.get('bonusNumbers'), bonus_count, bonus_max)
        multiplier = primary.get('multipliers')
        if game == 'powerball':
            if not isinstance(multiplier, list) or len(multiplier) != 1 or type(multiplier[0]) is not int or multiplier[0] not in (2, 3, 4, 5, 10):
                raise ValueError('Invalid Power Play multiplier')
        elif multiplier not in (None, []):
            raise ValueError('Unexpected drawing-wide multiplier')
        local = at.astimezone(MOUNTAIN)
        output.append({
            'game': game, 'drawId': draw_id, 'drawTimeUtc': at.isoformat(),
            'drawDate': local.date().isoformat(), 'timeZone': 'America/Denver',
            'numbers': main, 'bonusNumbers': bonus,
            # Official UI renders 2by2 bonusNumbers in red and primary in white.
            'numberLabel': 'White' if game == '2by2' else 'Main',
            'bonusLabel': 'Red' if game == '2by2' else 'Bonus',
            'multiplier': multiplier[0] if game == 'powerball' else None,
            'reportStatus': 'unavailable', 'sourceRetrievedAt': retrieved_at,
            'sourceUrl': 'https://wyolotto.com/wyo-wins/check-your-numbers',
        })
    if not output:
        raise ValueError('No completed drawings')
    output.sort(key=lambda r: r['drawTimeUtc'], reverse=True)
    if any(a['drawId'] <= b['drawId'] for a, b in zip(output, output[1:])):
        raise ValueError('Drawing IDs/time order disagree')
    return output


KENO_ID = 'e4c6419b-8e17-439d-a0c8-6ba2630e8149'


def parse_keno(payload, *, first_id, last_id, start, end, retrieved_at):
    """Validate inclusive requested IDs without asserting gap-free history."""
    if (type(first_id) is not int or type(last_id) is not int
            or first_id <= 0 or last_id < first_id
            or not isinstance(payload, list) or not payload):
        raise ValueError('Invalid Keno request/response')
    lo, hi, captured = map(instant, (start, end, retrieved_at))
    if lo > hi or hi > captured:
        raise ValueError('Invalid Keno time window')
    output, ids, times = [], set(), set()
    for row in payload:
        if not isinstance(row, dict) or set(row) - {'result', 'jackpot'}:
            raise ValueError('Unknown Keno envelope')
        raw = row.get('result')
        if not isinstance(raw, dict) or raw.get('rapidGameId') != KENO_ID:
            raise ValueError('Wrong Keno identity')
        if raw.get('secondary') is not None or raw.get('sequenceNumber') is not None:
            raise ValueError('Unknown Keno variant')
        draw_id = raw.get('drawingNumber')
        if type(draw_id) is not int or not first_id <= draw_id <= last_id or draw_id in ids:
            raise ValueError('Invalid/duplicate/out-of-range Keno draw ID')
        at = instant(raw.get('drawingDate'))
        if not lo <= at <= hi or at < SUPPORTED_FROM or at in times:
            raise ValueError('Invalid/duplicate Keno time')
        primary = raw.get('primary')
        if not isinstance(primary, dict) or set(primary) - {'winningNumbers', 'bonusNumbers', 'multipliers'}:
            raise ValueError('Unknown Keno number structure')
        main = numbers(primary.get('winningNumbers'), 20, 80)
        numbers(primary.get('bonusNumbers'), 0, 0)
        if primary.get('multipliers') not in (None, []):
            raise ValueError('Unknown Keno multiplier')
        ids.add(draw_id)
        times.add(at)
        output.append({'game': 'keno', 'drawId': draw_id,
                       'drawTimeUtc': at.isoformat(),
                       'drawDate': at.astimezone(MOUNTAIN).date().isoformat(),
                       'timeZone': 'America/Denver', 'numbers': main,
                       'reportStatus': 'unavailable',
                       'sourceRetrievedAt': retrieved_at,
                       'sourceUrl': 'https://wyolotto.com/games/keno'})
    output.sort(key=lambda r: r['drawId'], reverse=True)
    if any(a['drawTimeUtc'] <= b['drawTimeUtc'] for a,b in zip(output,output[1:])):
        raise ValueError('Keno draw IDs/time order disagree')
    return output
