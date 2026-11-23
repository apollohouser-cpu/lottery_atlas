"""Audited CT Lotto, Xs & Os and Millionaire for Life payout rows."""
from datetime import date
import math
import re

CONFIG = {
    'lotto': [('6', None), ('5', None), ('4', None), ('3', None)],
    'xsandos': [('8 teams', None), ('7 teams', None), ('6 teams', None),
                ('5 teams', None), ('4 teams', None)],
    'mfl': [('5 + Millionaire Ball', '$1,000,000 a Year for Life'),
            ('5', '$100,000 a Year for Life'), ('4 + Millionaire Ball', None),
            ('4', None), ('3 + Millionaire Ball', None), ('3', None),
            ('2 + Millionaire Ball', None), ('2', None), ('1 + Millionaire Ball', None)],
}


def parse(payload, *, game, draw_id, draw_date, observed_date):
    if game not in CONFIG or type(draw_id) is not int or draw_id <= 0:
        raise ValueError('Unsupported report or draw identity')
    if not isinstance(draw_date, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', draw_date):
        raise ValueError('Missing explicit draw date')
    if date.fromisoformat(draw_date) > observed_date:
        raise ValueError('Future draw date')
    if (payload.get('game') != game or type(payload.get('draw')) is not int or
            payload['draw'] != draw_id or payload.get('drawFound') is not True):
        raise ValueError('Mismatched or missing report')
    counts, amounts = payload.get('counts'), payload.get('amounts')
    keys = {str(n) for n in range(1, len(CONFIG[game])+1)}
    if not isinstance(counts, dict) or not isinstance(amounts, dict) or set(counts) != keys or set(amounts) != keys:
        raise ValueError('Incomplete or changed report tiers')
    rows = []
    for n, (match, life_label) in enumerate(CONFIG[game], 1):
        key = str(n); count = counts[key]; amount = amounts[key]
        if type(count) is not int or count < 0:
            raise ValueError('Invalid reported count')
        if type(amount) not in (int, float) or not math.isfinite(amount) or amount < 0:
            raise ValueError('Invalid reported prize')
        row = dict(sourceTier=key, match=match, reportedWinningTickets=count)
        if life_label:
            # API top-tier numbers are not established as annual/full/cash value.
            row.update(prizeLabel=life_label, numericPrizeWithheldReason='Life-prize API amount meaning unverified')
        else:
            row['reportedPrizeAmount'] = amount
        rows.append(row)
    return dict(game=game, drawId=draw_id, drawDate=draw_date,
        dateEvidence='Result-source date and request parameter; response echoes draw ID only',
        sourceUrl=f'https://ctlottery.com/api/winning-payouts?game={game}&draw={draw_id}&date={draw_date}',
        countLabel='Winning Tickets' if game == 'lotto' else 'CT Winning Tickets', rows=rows,
        limitations=['Literal dated source tiers; no retailer allocation or claim dates.',
                    'Reported prize amount is not proof of an individual cash payment.',
                    'No statewide distinct-ticket total derived.'])
