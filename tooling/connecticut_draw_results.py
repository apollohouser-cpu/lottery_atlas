"""Normalize bounded CT result snapshots; no payouts, claims or geography."""
from datetime import date
import json
from pathlib import Path
import re

# Audited game-detail number pools; these are not prize-count definitions.
POOLS = {'powerball': (5, 69, 26, 'Powerball'),
         'megamillions': (5, 70, 24, 'Mega Ball'),
         'mfl': (5, 58, 5, 'Millionaire Ball'),
         'lotto': (6, 44, None, ''), 'cash5': (5, 35, None, ''),
         'keno': (20, 80, None, ''), 'xsandos': (8, 32, None, '')}


def integer(value, low, high):
    if type(value) is not int or not low <= value <= high:
        raise ValueError('Invalid result integer')
    return value


def normalize(game, observed_date):
    """Validate one product without resolving Flight references or inventing dates."""
    slug = game['apiSlug']
    if slug not in POOLS and slug not in {'play3', 'play4'}:
        raise ValueError('Product requires separate semantic audit')
    route = game['detailsUrl']
    expected_route = '/games/draw-games/' + {'mfl': 'millionaireforlife', 'xsandos': 'xo'}.get(slug, slug)
    if route != expected_route:
        raise ValueError('Game/source mismatch')
    digit_game = slug in {'play3', 'play4'}
    draws = game.get('draws') if digit_game else [game.get('latest')]
    if not isinstance(draws, list) or len(draws) != (2 if digit_game else 1):
        raise ValueError('Missing result sessions')
    result, sessions = [], set()
    for draw in draws:
        if not isinstance(draw, dict):
            raise ValueError('Unresolved draw reference')
        iso = draw.get('isoDate', '')
        if not isinstance(iso, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', iso):
            raise ValueError('Missing explicit source date')
        if date.fromisoformat(iso) > observed_date:
            raise ValueError('Future source date')
        session = draw.get('drawLabel') if digit_game else None
        if digit_game and (session not in {'Day', 'Night'} or session in sessions):
            raise ValueError('Missing or duplicate named session')
        sessions.add(session)
        count, maximum, special_max, label = ((int(slug[-1]), 9, 9, 'Wild Ball')
                                               if digit_game else POOLS[slug])
        balls = draw.get('white')
        if not isinstance(balls, list) or len(balls) != count:
            raise ValueError('Wrong number count')
        balls = [integer(n, 0 if digit_game else 1, maximum) for n in balls]
        if not digit_game and len(set(balls)) != len(balls):
            raise ValueError('Duplicate pool numbers')
        special = draw.get('special')
        if special_max is None:
            if special is not None or draw.get('specialLabel') not in ('', None):
                raise ValueError('Unexpected bonus number')
        else:
            integer(special, 0 if digit_game else 1, special_max)
            if draw.get('specialLabel') != label:
                raise ValueError('Bonus meaning changed')
        # Reconcile explicit API payloads to visible result fields. Generic
        # multiplier keys in digit games are intentionally never imported.
        if slug != 'keno':
            payouts = game.get('payouts', [])
            if not isinstance(payouts, list) or len(payouts) != (2 if digit_game else 1):
                raise ValueError('Missing reconciliation payload')
            api = slug + (session.lower() if digit_game else '')
            matching = [p for p in payouts if p.get('apiGame') == api]
            if len(matching) != 1:
                raise ValueError('Ambiguous reconciliation payload')
            raw = matching[0]['draw']
            if raw.get('drawDate') != iso or raw.get('whiteBalls') != balls:
                raise ValueError('Display/API result mismatch')
            if special_max is not None:
                key = 'powerPlayMultiplier' if digit_game else 'powerball'
                if type(raw.get(key)) is not int or raw[key] != special:
                    raise ValueError('Display/API bonus mismatch')
        row = {'game': slug, 'drawDate': iso, 'numbers': balls,
               'sourceUrl': 'https://ctlottery.com' + route,
               'datePrecision': 'day',
               'coverage': 'Observed result snapshot; no winning-ticket counts or retailer allocation.'}
        if session:
            row['session'] = session
        if special_max is not None:
            row['special'] = {'label': label, 'number': special}
        if slug == 'powerball':
            multiplier = draw.get('multiplier', '')
            if not re.fullmatch(r'Power Play® (2|3|4|5|10)X', multiplier):
                raise ValueError('Unknown Power Play multiplier')
            row['powerPlay'] = int(multiplier.split()[-1][:-1])
        if slug == 'keno':
            number = game.get('kenoGameNo')
            bonus = game.get('kenoBonus')
            if not isinstance(number, str) or not re.fullmatch(r'[1-9]\d*', number):
                raise ValueError('Missing Keno game number')
            if bonus not in {'No Bonus', '2X', '3X', '4X', '5X', '10X'}:
                raise ValueError('Unknown Keno bonus')
            row.update(gameNumber=number, bonus=bonus)
        if slug == 'xsandos':
            mapping = json.loads(Path(__file__).with_name('connecticut_xsos_teams.json').read_text())['teams']
            if len(mapping) != 32 or {t['number'] for t in mapping} != set(range(1, 33)):
                raise ValueError('Incomplete reviewed team map')
            by_number = {t['number']: t['name'] for t in mapping}
            row['teams'] = [by_number[n] for n in balls]
        result.append(row)
    return result


def normalize_double_play(game, observed_date, *, inventory_index):
    """Use the explicitly dated Powerball API draw's nested Double Play object.

Resolve only its narrow, same-product/same-display white-ball reference. Never
substitute the retrieval date or follow an arbitrary React Flight reference.
"""
    if game.get('apiSlug') != 'powerball' or type(inventory_index) is not int or inventory_index < 0:
        raise ValueError('Wrong Double Play parent')
    parent = normalize(game, observed_date)[0]
    displays = game.get('draws')
    if not isinstance(displays, list) or len(displays) != 2:
        raise ValueError('Missing separate Double Play display')
    display = displays[1]
    if not isinstance(display, dict) or display.get('sectionLabel') != 'Double Play®':
        raise ValueError('Double Play display identity changed')
    if display.get('specialLabel') != 'Powerball':
        raise ValueError('Double Play bonus identity changed')
    balls = display.get('white')
    if not isinstance(balls, list) or len(balls) != 5:
        raise ValueError('Invalid Double Play number count')
    balls = [integer(n, 1, 69) for n in balls]
    if len(set(balls)) != 5:
        raise ValueError('Duplicate Double Play numbers')
    bonus = integer(display.get('special'), 1, 26)
    # Parent's explicit date was already reconciled against its visible result.
    raw = game['payouts'][0]['draw']
    nested = raw.get('doublePlay')
    if not isinstance(nested, dict):
        raise ValueError('Missing dated nested Double Play result')
    raw_balls = nested.get('whiteBalls')
    if isinstance(raw_balls, str):
        suffix = f':props:data:games:{inventory_index}:draws:1:white'
        if not re.fullmatch(r'\$[0-9a-f]+' + re.escape(suffix), raw_balls):
            raise ValueError('Unresolved or cross-product Double Play reference')
        root = raw_balls.split(':', 1)[0]
        if displays[0] != f'{root}:props:data:games:{inventory_index}:latest':
            raise ValueError('Double Play reference root differs from parent')
    elif (not isinstance(raw_balls, list) or
          any(type(n) is not int for n in raw_balls) or raw_balls != balls):
        raise ValueError('Double Play display/API mismatch')
    if type(nested.get('powerball')) is not int or nested['powerball'] != bonus:
        raise ValueError('Double Play bonus mismatch')
    if display.get('isoDate') not in (None, '', parent['drawDate']):
        raise ValueError('Conflicting Double Play date')
    return {'game': 'doubleplay', 'drawDate': parent['drawDate'], 'numbers': balls,
            'special': {'label': 'Powerball', 'number': bonus},
            'sourceUrl': parent['sourceUrl'], 'datePrecision': 'day',
            'dateEvidence': 'Nested Double Play in explicitly dated Powerball API draw',
            'coverage': parent['coverage']}
