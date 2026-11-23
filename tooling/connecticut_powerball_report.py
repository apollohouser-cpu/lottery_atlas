"""Keep CT Powerball, Power Play and Double Play report measures separate."""
from datetime import date
import math
import re

MATCHES = ['5 + Powerball', '5', '4 + Powerball', '4', '3 + Powerball',
           '3', '2 + Powerball', '1 + Powerball', '0 + Powerball']


def count(value):
    if type(value) is not int or value < 0:
        raise ValueError('Invalid count')
    return value


def amount(value):
    if type(value) not in (int, float) or not math.isfinite(value) or value < 0:
        raise ValueError('Invalid amount')
    return value


def parse(payload, *, draw_id, draw_date, observed_date):
    if (type(draw_id) is not int or draw_id <= 0 or payload.get('game') != 'powerball' or
            type(payload.get('draw')) is not int or payload['draw'] != draw_id or
            payload.get('drawFound') is not True):
        raise ValueError('Mismatched report identity')
    if not isinstance(draw_date, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', draw_date):
        raise ValueError('Missing explicit result date')
    if date.fromisoformat(draw_date) > observed_date:
        raise ValueError('Future draw')
    keys = {str(n) for n in range(1, 19)}
    for field in ['counts', 'amounts', 'multipliers']:
        if not isinstance(payload.get(field), dict) or set(payload[field]) != keys:
            raise ValueError('Missing or changed report tiers')
    primary, double = [], []
    for n in range(1, 19):
        key = str(n); extra = payload['multipliers'][key]
        if not isinstance(extra, dict) or set(extra) - {'powerplay', 'pp_amount'}:
            raise ValueError('Unknown multiplier fields')
        row = dict(sourceTier=key, match=MATCHES[(n-1) % 9],
                   reportedWinningTickets=count(payload['counts'][key]))
        raw_amount = amount(payload['amounts'][key])
        if n == 1:
            row['prizeLabel'] = 'Jackpot (individual payment not established)'
        else:
            row['reportedPrizeAmount'] = raw_amount
        if 'pp_amount' in extra:
            amount(extra['pp_amount'])
        if n <= 9:
            # Omitted source fields remain unknown, not synthetic zero winners.
            row['withPowerPlay'] = count(extra['powerplay']) if 'powerplay' in extra else None
            row['powerPlayPrizeAmount'] = extra.get('pp_amount') if n != 1 else None
            row['countMeaning'] = 'Base source count; Power Play count shown separately'
            primary.append(row)
        else:
            if 'powerplay' in extra:
                raise ValueError('Power Play cannot apply to Double Play')
            double.append(row)
    return dict(game='powerball', drawId=draw_id, drawDate=draw_date,
        dateEvidence='Audited result and request date; report echoes draw ID only',
        sourceUrl=f'https://ctlottery.com/api/winning-payouts?game=powerball&draw={draw_id}&date={draw_date}',
        rows=primary, doublePlayRows=double,
        limitations=['Source base and Power Play counts are separate; no cross-game total.',
                     'Missing Power Play fields stay unknown.',
                     'Double Play is a separate drawing; no Power Play multiplier applied.',
                     'No retailer locations or individual cash payment inferred.'])
