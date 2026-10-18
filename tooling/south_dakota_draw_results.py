"""Strict bounded South Dakota results. Prize/count reporting is a separate contract."""
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
import re

CENTRAL = ZoneInfo('America/Chicago')
# Slug: official identifier, primary count/max, secondary max, local weekdays.
SPECS = {
    'powerball-power-play': ('Powerball', 5, 69, 26, {0, 2, 5}),
    'mega-millions': ('Mega Millions', 5, 70, 24, {1, 4}),
    'dakota-cash': ('Dakota Cash', 5, 35, 0, {2, 5}),
    'millionaire-for-life': ('Million 4 Life', 5, 58, 5, set(range(7))),
    'lotto-america': ('Lotto America', 5, 52, 10, {0, 2, 5}),
    'xs-and-os': ('Xs and Os', 8, 32, 0, {6}),
}


def numbers(value, count, maximum):
    if not isinstance(value, list) or len(value) != count:
        raise ValueError('Wrong result cardinality')
    if any(not isinstance(v, str) or not re.fullmatch(r'[1-9][0-9]*', v)
           or not 1 <= int(v) <= maximum for v in value):
        raise ValueError('Invalid result domain')
    if len(set(value)) != len(value):
        raise ValueError('Duplicate result value')
    return list(value)


def parse_results(payload, slug, *, now=None):
    """Read exactly two completed source records, preserving raw date and variant.

    OPEN records never become completed results. No API prize amount, winner
    count or advertised jackpot is copied into this number-only output.
    """
    identifier, count, maximum, secondary_max, weekdays = SPECS[slug]
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        raise ValueError('Aware reference clock required')
    rows = payload.get('draws') if isinstance(payload, dict) else None
    if not isinstance(rows, list) or len(rows) != 3:
        raise ValueError('Unexpected bounded response')
    completed, seen_ids, seen_dates, open_count = [], set(), set(), 0
    for row in rows:
        if not isinstance(row, dict) or row.get('gameName') != identifier:
            raise ValueError('Wrong game identity')
        ident, stamp = row.get('id'), row.get('drawTime')
        if not isinstance(ident, str) or not re.fullmatch(r'[1-9][0-9]*', ident) or ident in seen_ids:
            raise ValueError('Invalid or duplicate draw identity')
        seen_ids.add(ident)
        if type(stamp) is not int or not 1577836800000 <= stamp <= 4102444800000:
            raise ValueError('Invalid draw timestamp')
        date = datetime.fromtimestamp(stamp / 1000, CENTRAL)
        if date.weekday() not in weekdays or row.get('drawDay') != [date.strftime('%A').upper()]:
            raise ValueError('Calendar mismatch')
        if date.date() in seen_dates:
            raise ValueError('Duplicate draw date')
        seen_dates.add(date.date())
        status = row.get('status')
        if status == 'OPEN':
            open_count += 1
            if row.get('results') or stamp <= now.timestamp() * 1000:
                raise ValueError('Invalid open draw')
            continue
        if status != 'PAYABLE' or stamp > now.timestamp() * 1000:
            raise ValueError('Not a completed result')
        results = row.get('results')
        expected = {'Regular', 'Double Play'} if identifier == 'Powerball' else {'Regular'}
        if not isinstance(results, list) or len(results) != len(expected):
            raise ValueError('Missing result variant')
        variants = set()
        for result in results:
            if not isinstance(result, dict):
                raise ValueError('Invalid result object')
            variant = result.get('prizeTierId')
            if variant not in expected or variant in variants:
                raise ValueError('Invalid or duplicate result variant')
            variants.add(variant)
            if set(result) - {'primary', 'secondary', 'multiplier', 'prizeTierId'}:
                raise ValueError('Unreviewed result field')
            primary = numbers(result.get('primary'), count, maximum)
            secondary = numbers(result.get('secondary', []), int(secondary_max > 0), secondary_max)
            multiplier = result.get('multiplier')
            allowed = ({2, 3, 4, 5, 10} if identifier == 'Powerball' else
                       {2, 3, 4, 5} if identifier == 'Lotto America' else set())
            if variant == 'Double Play':
                allowed = set()
            if allowed:
                if type(multiplier) is not int or multiplier not in allowed:
                    raise ValueError('Invalid draw multiplier')
            elif 'multiplier' in result:
                raise ValueError('Unexpected draw multiplier')
            source_slug = 'powerball-double-play' if variant == 'Double Play' else slug
            completed.append(dict(game=identifier, variant=variant, drawId=ident,
                                  rawDrawTime=stamp, drawDate=date.date().isoformat(),
                                  dateZone='America/Chicago', primary=primary,
                                  secondary=secondary, multiplier=multiplier,
                                  sourceUrl=f'https://lottery.sd.gov/game/{source_slug}/'))
    if open_count != 1 or len(completed) != (4 if identifier == 'Powerball' else 2):
        raise ValueError('Incomplete bounded collection')
    return sorted(completed, key=lambda r: (r['drawDate'], r['variant']), reverse=True)
