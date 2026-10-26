"""Strict bounded New Mexico archive results; no winner counts or publication."""
from datetime import date, datetime
import re
from lxml import html

GAMES = {
    'powerball': ('Powerball', 5, 69, 26),
    'megamillions': ('Mega Millions', 5, 70, 24),
    'lottoamerica': ('Lotto America', 5, 52, 10),
    'roadrunnercash': ('Roadrunner Cash', 5, 37, None),
    'pick3plus': ('Pick 3 Plus', 3, 9, None),
    'pick4plus': ('Pick 4 Plus', 4, 9, None),
}
MULTIPLIERS = {'powerball': ('Power Play multiplier: ', {2, 3, 4, 5, 10}),
               'lottoamerica': ('All Star Bonus Multiplier: ', {2, 3, 4, 5})}
CLASSES = dict(zip(GAMES, ['powerball', 'mega-millions', 'lotto-america', 'roadrunner-cash', 'pick-3-plus', 'pick-4-plus']))
BASE = 'https://nmlotterydynamic.sks.com/rts/games/pastdrawings/'


def plain(node):
    return ' '.join(node.text_content().split())


def one(nodes, label):
    if len(nodes) != 1:
        raise ValueError('Missing/duplicate ' + label)
    return nodes[0]


def balls(node, game):
    _, size, maximum, special_max = GAMES[game]
    pick = game.startswith('pick')
    cells = node.xpath('./li')
    if len(cells) != size + (special_max is not None):
        raise ValueError('Wrong ball count')
    values = [plain(c) for c in cells]
    if any(not re.fullmatch(r'[0-9]' if pick else r'[0-9]{1,2}', v) for v in values):
        raise ValueError('Invalid ball text')
    for i, cell in enumerate(cells):
        expected = 'special-ball' if i == size and special_max else ''
        if cell.get('class', '') != expected:
            raise ValueError('Changed special ball identity')
    regular = [int(v) for v in values[:size]]
    if any(v < (0 if pick else 1) or v > maximum for v in regular):
        raise ValueError('Ball outside range')
    if not pick and len(set(regular)) != size:
        raise ValueError('Duplicate main balls')
    special = int(values[-1]) if special_max else None
    if special is not None and not 1 <= special <= special_max:
        raise ValueError('Special ball outside range')
    return values[:size], special


def parse_results(raw, game, *, start, end, today):
    """Validate every returned row before selection. Dates are source-local dates."""
    if game not in GAMES or not date(2025, 4, 8) <= start <= end <= today:
        raise ValueError('Unsupported game or current-format date window')
    tree = html.fromstring(raw)
    container = one(tree.xpath('//div[@class="draw-results ' + CLASSES[game] + '"]'), 'game container')
    if plain(one(container.xpath('./h2'), 'game heading')) != GAMES[game][0]:
        raise ValueError('Wrong game heading')
    rows = container.xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," result ")]')
    if not rows:
        raise ValueError('No completed results')
    output = []; seen = set()
    for row in rows:
        heading = plain(one(row.xpath('./h3'), 'draw date'))
        m = re.fullmatch(r'(\d{1,2}/\d{1,2}/\d{4})(?: (DAY|EVE))?', heading)
        if not m:
            raise ValueError('Invalid draw date/session')
        day = datetime.strptime(m[1], '%m/%d/%Y').date(); session = m[2]
        pick = game.startswith('pick')
        if pick != (session is not None) or not start <= day <= end:
            raise ValueError('Unexpected session or out-of-window date')
        if row.get('class') != ('result ' + (session or '') + '-draw'):
            raise ValueError('Conflicting session class')
        identity = (day, session)
        if identity in seen:
            raise ValueError('Duplicate draw identity')
        seen.add(identity)
        numbers, special = balls(one(row.xpath('./ul[@class="winning-numbers"]'), 'numbers'), game)
        info = plain(one(row.xpath('./div[@class="fp draw-info"]'), 'draw info'))
        multiplier = None
        if game in MULTIPLIERS:
            prefix, valid = MULTIPLIERS[game]
            if not info.startswith(prefix) or info[len(prefix):] not in {str(n) for n in valid}:
                raise ValueError('Invalid multiplier')
            multiplier = int(info[len(prefix):])
        elif info:
            raise ValueError('Unexpected draw information')
        record = dict(game=game, variant='base', date=day.isoformat(), session=session,
                      numbers=numbers, specialBall=special, multiplier=multiplier,
                      reportStatus='unavailable', sourceUrl=BASE + '#game=' + game)
        output.append(record)
        wrapper = one(row.xpath('./div[@class="double-play-wrap"]'), 'Double Play wrapper')
        if game == 'powerball':
            dp = one(wrapper.xpath('.//ul[@class="double-play winning-numbers"]'), 'Double Play numbers')
            if plain(one(wrapper.xpath('.//strong'), 'Double Play label')) != 'Double Play:':
                raise ValueError('Changed Double Play label')
            nums, bonus = balls(dp, game)
            output.append(dict(record, variant='double_play', numbers=nums, specialBall=bonus, multiplier=None))
        elif plain(wrapper) or len(wrapper):
            raise ValueError('Unexpected Double Play data')
    return sorted(output, key=lambda r: (r['date'], r['session'] or '', r['variant']), reverse=True)


def latest_two(records):
    """Bound each available group without filling absent dates or sessions."""
    groups = {}
    for record in records:
        key = (record['game'], record['variant'], record['session'])
        groups.setdefault(key, []).append(record)
    result = []
    for key in sorted(groups, key=str):
        rows = sorted(groups[key], key=lambda r: r['date'], reverse=True)
        if len({r['date'] for r in rows}) != len(rows):
            raise ValueError('Duplicate group date')
        result.extend(rows[:2])
    return result
