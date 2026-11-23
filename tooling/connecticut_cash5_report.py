"""Literal Cash5 payout tiers; no sum across base and Kicker claims."""
from datetime import date
import math
import re

# Official CT client d56e18069f9b6da0.js Cash5 `igt` tier mapping.
TIERS = ('5', '4', '3', '4 + Kicker', '3 + Kicker', '2 + Kicker', '1 + Kicker')
KEYS = {str(n) for n in range(1, 8)}


def parse(payload, *, draw_id, draw_date, observed_date):
    """Caller supplies a draw ID/date already audited from the result source.

The endpoint echoes draw ID but not date. Keep that provenance distinction.
"""
    if type(draw_id) is not int or draw_id <= 0:
        raise ValueError('Invalid expected draw identity')
    if not isinstance(draw_date, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', draw_date):
        raise ValueError('Missing explicit expected draw date')
    if date.fromisoformat(draw_date) > observed_date:
        raise ValueError('Future expected draw date')
    if (payload.get('game') != 'cash5' or type(payload.get('draw')) is not int or
            payload['draw'] != draw_id or payload.get('drawFound') is not True):
        raise ValueError('Report identity missing or mismatched')
    counts, amounts = payload.get('counts'), payload.get('amounts')
    if not isinstance(counts, dict) or set(counts) != KEYS:
        raise ValueError('Missing or changed count tiers')
    if not isinstance(amounts, dict) or set(amounts) != KEYS:
        raise ValueError('Missing or changed prize tiers')
    rows = []
    for key, label in zip(map(str, range(1, 8)), TIERS):
        count, amount = counts[key], amounts[key]
        if type(count) is not int or count < 0:
            raise ValueError('Invalid literal count')
        if type(amount) not in (int, float) or not math.isfinite(amount) or amount < 0:
            raise ValueError('Invalid literal prize')
        rows.append({'sourceTier': key, 'match': label,
                     'reportedWinningTickets': count, 'reportedPrizeAmount': amount})
    return {'game': 'cash5', 'drawId': draw_id, 'drawDate': draw_date,
            'dateEvidence': 'Result-source date and request parameter; response echoes draw ID only',
            'sourceUrl': f'https://ctlottery.com/api/winning-payouts?game=cash5&draw={draw_id}&date={draw_date}',
            'countLabel': 'Winning Tickets', 'rows': rows,
            'limitations': ['Literal official payout-report tiers, not retailer activity.',
                'Base and Kicker tiers are not summed into a distinct-ticket total.',
                'Kicker report amounts are separate from advertised combined prize figures.',
                'No claim date, selling location or source publication time supplied.']}
