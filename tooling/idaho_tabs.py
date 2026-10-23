"""Typed Idaho Tab schedules with exact reviewed source contracts."""
import json
from decimal import Decimal
from pathlib import Path
from tooling.idaho_instaplay import _extract

SPECS = json.loads(Path(__file__).with_name('idaho_tab_specs.json').read_text())
TOUCH_HEADERS = ['Wager Amount *', 'Top Prize Amount', 'Overall Odds']
FIXED_HEADERS = ['Number of Prizes', 'Prize Amount', 'Odds']


def _cents(value):
    return int(Decimal(value.removeprefix('$').replace(',', '')) * 100)


def parse_detail(raw, slug):
    if slug not in SPECS or _extract(raw) != SPECS[slug]:
        raise ValueError('Unreviewed or changed Idaho Tab detail')
    spec = SPECS[slug]
    touch = spec['headers'] == TOUCH_HEADERS
    if not touch and spec['headers'] != FIXED_HEADERS:
        raise ValueError('Unknown Tab schedule type')
    rows = []
    for row in spec['rows']:
        first, prize, odds = row['cells']
        if touch:
            rows.append({'wagerCents': _cents(first), 'topPrizeCents': _cents(prize),
                         'sourceWagerLabel': first, 'sourcePrizeLabel': prize,
                         'sourceOverallOdds': odds})
        else:
            rows.append({'schedulePrizeCount': int(first), 'prizeCents': _cents(prize),
                         'sourcePrizeLabel': prize, 'sourceOdds': odds})
    return {'productType': 'tab', 'scheduleType': 'touch_wager' if touch else 'fixed_prize',
            'slug': slug, 'name': spec['title'].removesuffix(' | Idaho Lottery'),
            'sourceUrl': f'https://www.idaholottery.com/games/tabs/{slug}',
            'rules': spec['rules'], 'sourceOddsText': spec['oddsText'], 'tiers': rows,
            'remainingPrizes': None,
            'limitation': 'Printed schedules are not remaining prizes, stock or claims. TouchTab rows give a top prize per wager, not every prize tier.'}
