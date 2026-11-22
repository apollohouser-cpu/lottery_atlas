"""Normalize bounded CT result snapshots; no payouts, claims or geography."""
from datetime import date
import re

# Audited game-detail number pools; these are not prize-count definitions.
POOLS = {'powerball': (5, 69, 26, 'Powerball'),
         'megamillions': (5, 70, 24, 'Mega Ball'),
         'mfl': (5, 58, 5, 'Millionaire Ball'),
         'lotto': (6, 44, None, ''), 'cash5': (5, 35, None, ''),
         'keno': (20, 80, None, '')}


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
    expected_route = '/games/draw-games/' + ('millionaireforlife' if slug == 'mfl' else slug)
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
        result.append(row)
    return result
