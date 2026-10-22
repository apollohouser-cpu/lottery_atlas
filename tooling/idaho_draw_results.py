"""Strict dated Idaho API result parsing; no prize/count fields are promoted."""
from datetime import date, datetime
import re
from zoneinfo import ZoneInfo


GAMES = {
    'powerball': 'Powerball', 'mega-millions': 'Mega Millions',
    'lotto-america': 'Lotto America', 'idaho-cash': 'Idaho Cash',
    'pick-3': 'Pick 3', 'pick-4': 'Pick 4',
    'powerball-xs-os': 'Powerball Xs & Os',
}
API = 'https://www.idaholottery.com/api/v1/drawgame/'


def _rows(rows, specs, unique=False):
    if not isinstance(rows, list) or len(rows) != len(specs):
        raise ValueError('Incomplete result array')
    values, labels = [], set()
    for index, (row, (prefix, low, high)) in enumerate(zip(rows, specs)):
        if not isinstance(row, dict):
            raise ValueError('Malformed result row')
        weight = row.get('weight')
        # Older official responses encode weights as canonical decimal strings.
        if not ((type(weight) is int and weight == index) or
                (type(weight) is str and weight == str(index))):
            raise ValueError('Changed result order')
        label = row.get('0')
        if not isinstance(label, str) or not re.fullmatch(re.escape(prefix) + r' [0-9]+', label) or label in labels:
            raise ValueError('Wrong or duplicate ball identity')
        labels.add(label)
        raw = row.get('1')
        if not isinstance(raw, str) or not re.fullmatch(r'[ \t\r\n]*[0-9]{1,2}[ \t\r\n]*', raw):
            raise ValueError('Malformed result value')
        value = raw.strip(' \t\r\n')
        if not low <= int(value) <= high:
            raise ValueError('Result out of range')
        values.append(value)
    if unique and len({int(x) for x in values}) != len(values):
        raise ValueError('Duplicate result')
    return values


def parse_results(payload, slug, requested_date, *, as_of=None):
    """Return one dated result per variant/session; do not infer missing groups."""
    if slug not in GAMES or not isinstance(requested_date, str):
        raise ValueError('Unsupported game/date')
    try:
        parsed_date = date.fromisoformat(requested_date)
    except ValueError as error:
        raise ValueError('Invalid date') from error
    if parsed_date.isoformat() != requested_date:
        raise ValueError('Noncanonical date')
    if parsed_date > (as_of or datetime.now(ZoneInfo('America/Boise')).date()):
        raise ValueError('Future result')
    if not isinstance(payload, dict) or payload.get('success') is not True:
        raise ValueError('Unsuccessful source response')
    data = payload.get('data')
    if not isinstance(data, dict) or data.get('game') != GAMES[slug] or data.get('draw_date') != requested_date:
        raise ValueError('Game/date mismatch')
    if data.get('title') != requested_date + '-' + GAMES[slug]:
        raise ValueError('Title identity mismatch')
    if slug not in ('pick-3', 'pick-4') and data.get('winning_numbers_2') is not None:
        raise ValueError('Unexpected second session')
    if slug != 'powerball' and data.get('winning_numbers_dp') is not None:
        raise ValueError('Unexpected Double Play')
    output = []

    def add(group, numbers, **extras):
        output.append(dict(group=group, game=GAMES[slug], drawDate=requested_date,
                           sourceUrl=API + slug + '/' + requested_date,
                           numbers=numbers, **extras))

    if slug in ('pick-3', 'pick-4'):
        size = int(slug[-1])
        for key, session in [('winning_numbers', 'day'), ('winning_numbers_2', 'night')]:
            rows = data.get(key)
            values = _rows(rows, [('white-balls', 0, 9)] * size)
            if any(len(v) != 1 for v in values) or [r['0'] for r in rows] != [f'white-balls {i}' for i in range(size)]:
                raise ValueError('Changed digit position/width')
            add(slug + '-' + session, values, session=session)
    elif slug == 'powerball-xs-os':
        values = _rows(data.get('winning_numbers'), [('nfl-logos', 1, 32)] * 8, unique=True)
        if any(len(v) != 2 for v in values):
            raise ValueError('Changed team code width')
        add(slug, values, numberMeaning='Literal official team image codes; not expanded team names',
            imageUrls=['https://d2kx0heugfrx3y.cloudfront.net/nfl/logos-with-names/' + v + '.png' for v in values])
    else:
        prefix, maximum = ('red-balls', 52) if slug == 'lotto-america' else ('white-balls', {'powerball': 69, 'mega-millions': 70, 'idaho-cash': 45}[slug])
        specs = [(prefix, 1, maximum)] * 5
        extras = {'powerball': [('powerball', 1, 26), ('power-play', 2, 10)],
                  'mega-millions': [('megaball', 1, 24)],
                  'lotto-america': [('star-ball', 1, 10), ('all-star-bonus', 2, 5)],
                  'idaho-cash': []}[slug]
        values = _rows(data.get('winning_numbers'), specs + extras)
        if len({int(v) for v in values[:5]}) != 5:
            raise ValueError('Duplicate main ball')
        fields = {}
        if extras:
            fields['specialNumber'] = values[5]
        if len(extras) == 2:
            multiplier = int(values[6])
            if multiplier not in ({2, 3, 4, 5, 10} if slug == 'powerball' else {2, 3, 4, 5}):
                raise ValueError('Invalid multiplier')
            fields['multiplier'] = multiplier
        add(slug, values[:5], **fields)
        if slug == 'powerball':
            dp = _rows(data.get('winning_numbers_dp'), [('black-balls', 1, 69)] * 5 + [('dp-powerball', 1, 26)])
            if len({int(v) for v in dp[:5]}) != 5:
                raise ValueError('Duplicate Double Play ball')
            add('powerball-double-play', dp[:5], specialNumber=dp[5])
    return output
