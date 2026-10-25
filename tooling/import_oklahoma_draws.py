"""Bounded Oklahoma completed results; unverified winner reports are excluded."""
from datetime import datetime, timezone
import re
from zoneinfo import ZoneInfo
from import_oklahoma_scratch_catalog import embedded, integer

# Source IDs, normal count/range, special range. Xs & Os values are literal codes.
CONTRACTS = {
    'powerball': (1, 5, 1, 69, 26),
    'megamillions': (4, 5, 1, 70, 24),
    'lotto-america': (2, 5, 1, 52, 10),
    'millionaire-for-life': (3, 5, 1, 58, 5),
    'pick3': (5, 3, 0, 9, 0),
    'cash-5': (6, 5, 1, 36, 0),
    'powerball-xs-os': (11, 8, 1, 32, 0),
}
SOURCE = 'https://oklottery.com/games/draw-games/'


def utc_time(value):
    if not isinstance(value, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', value):
        raise ValueError('Invalid source UTC timestamp')
    return datetime.fromisoformat(value.replace('Z', '+00:00'))


def parse_results(raw, slug, retrieved_at):
    """Require caller's actual retrieval time; replay must retain that provenance."""
    if slug not in CONTRACTS:
        raise ValueError('Unknown game contract')
    if not isinstance(retrieved_at, datetime) or retrieved_at.tzinfo is None:
        raise ValueError('Missing retrieval timezone')
    gid, count, minimum, maximum, special = CONTRACTS[slug]
    cms = embedded(raw, 'cms')
    if not isinstance(cms, dict) or type(cms.get('gameId')) is not int or cms['gameId'] != gid:
        raise ValueError('CMS identity mismatch')
    if cms.get('gameNumber') != str(gid) or cms.get('slug') != slug or 'endDate' not in cms or cms['endDate'] is not None:
        raise ValueError('Changed CMS identity or eligibility')
    payload = cms.get('jackpotResults')
    if not isinstance(payload, dict) or not isinstance(payload.get('game'), dict):
        raise ValueError('Missing result envelope')
    game = payload['game']
    if type(game.get('gameId')) is not int or game['gameId'] != gid:
        raise ValueError('Envelope game mismatch')
    records = payload.get('jackpotResults')
    if not isinstance(records, list) or not 1 <= len(records) <= 2:
        raise ValueError('Changed bounded result window')
    results, seen_ids, seen_dates = [], set(), set()
    excluded = 0

    def parse(record, variant):
        nonlocal excluded
        if not isinstance(record, dict):
            raise ValueError('Invalid result')
        identity = integer(record.get('id'), True)
        if identity in seen_ids:
            raise ValueError('Duplicate result identity')
        seen_ids.add(identity)
        if type(record.get('gameId')) is not int or record['gameId'] != gid:
            raise ValueError('Result game mismatch')
        stamp = utc_time(record.get('drawDateTimeUTC'))
        if record.get('drawingDateUTC') != stamp.date().isoformat():
            raise ValueError('UTC date mismatch')
        local_date = stamp.astimezone(ZoneInfo('America/Chicago')).date().isoformat()
        key = (variant, local_date)
        if key in seen_dates:
            raise ValueError('Ambiguous same-date result/session')
        seen_dates.add(key)
        status = record.get('jackpotStatus')
        data = record.get('resultData')
        if status == 'SCHEDULED':
            if data != [] or record.get('prizeTiers') != [] or record.get('multiplier') is not None:
                raise ValueError('Scheduled entry contains result values')
            excluded += 1
            return stamp, status
        if status != 'COMPLETE' or stamp > retrieved_at:
            raise ValueError('Invalid completion status or future completed result')
        if not isinstance(data, list) or len(data) != count + bool(special):
            raise ValueError('Invalid ball cardinality')
        normal, bonus = [], None
        for index, ball in enumerate(data):
            if not isinstance(ball, dict) or type(ball.get('order')) is not int or ball['order'] != index:
                raise ValueError('Invalid result order')
            value = integer(ball.get('data'))
            is_bonus = index == count
            if ball.get('type') != ('SPECIAL' if is_bonus else 'NORMAL'):
                raise ValueError('Invalid ball type')
            low, high = (1, special) if is_bonus else (minimum, maximum)
            if not low <= value <= high:
                raise ValueError('Ball outside game range')
            if is_bonus:
                bonus = value
            else:
                normal.append(value)
        if slug != 'pick3' and len(set(normal)) != count:
            raise ValueError('Duplicate normal ball')
        if 'multiplier' not in record:
            raise ValueError('Missing multiplier field')
        multiplier = record['multiplier']
        allowed = {2, 3, 4, 5, 10} if slug == 'powerball' else {2, 3, 4, 5}
        needs_multiplier = variant == 'base' and slug in ('powerball', 'lotto-america')
        if needs_multiplier:
            if type(multiplier) is not int or multiplier not in allowed:
                raise ValueError('Invalid game multiplier')
        elif multiplier is not None:
            raise ValueError('Unexpected draw-wide multiplier')
        # Do not copy source prizeTiers: geographic/count/payout semantics unverified.
        results.append(dict(game=slug, variant=variant, date=local_date,
                            drawDateTimeUTC=record['drawDateTimeUTC'], numbers=normal,
                            specialBall=bonus, multiplier=multiplier,
                            valueKind='source_codes' if slug == 'powerball-xs-os' else 'numbers',
                            session=None, sessionStatus='unavailable' if slug == 'pick3' else 'not_applicable',
                            reportStatus='unavailable',
                            reportNote='Winner count geography and payout semantics are unverified.',
                            sourceUrl=SOURCE+slug,
                            retrievedAt=retrieved_at.astimezone(timezone.utc).isoformat()))
        return stamp, status

    last = None
    for record in records:
        stamp, status = parse(record, 'base')
        if last is not None and stamp >= last:
            raise ValueError('Result window not newest first')
        last = stamp
        if slug == 'powerball':
            nested = record.get('doublePlayResult')
            dp_stamp, dp_status = parse(nested, 'double_play')
            if dp_status != status or dp_stamp <= stamp or dp_stamp.astimezone(ZoneInfo('America/Chicago')).date() != stamp.astimezone(ZoneInfo('America/Chicago')).date():
                raise ValueError('Double Play parent join mismatch')
        elif record.get('doublePlayResult') is not None:
            raise ValueError('Unexpected Double Play result')
    if not results:
        raise ValueError('No completed results')
    return dict(results=results, excludedScheduled=excluded)
