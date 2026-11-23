"""Preserve separate Powerball/Double Play and Power Play reference columns."""
import re
from tooling.connecticut_keno_prizes import Tables


def parse(html):
    parser = Tables(); parser.feed(html)
    tables = parser.tables
    if len(tables) != 2:
        raise ValueError('Changed Powerball reference table inventory')
    base, power = tables
    if (base['rows'][0] != ['Match', 'Powerball Prize', 'Double PlayPrize', 'Odds'] or
            power['rows'][0] != ['Match', '2XPrize', '3XPrize', '4XPrize', '5XPrize', '10XPrize'] or
            len(base['rows']) != 10 or len(power['rows']) != 10):
        raise ValueError('Changed Powerball reference headers or tiers')
    for row in base['rows'][1:]:
        if len(row) != 4 or not row[0] or not re.fullmatch(r'1 in [\d,]+', row[3]):
            raise ValueError('Invalid base/Double Play reference row')
        if any(not (v.startswith('$') or v == 'JACKPOT') for v in row[1:3]):
            raise ValueError('Invalid reference prize')
    if (power['rows'][1] != [base['rows'][1][0], 'Power Play does not multiply jackpot amount'] or
            power['rows'][2] != [base['rows'][2][0], '$2 MILLION']):
        raise ValueError('Changed merged Power Play exceptions')
    for original, row in zip(base['rows'][3:], power['rows'][3:]):
        if len(row) != 6 or row[0] != original[0] or any(not re.fullmatch(r'\$[\d,]+', v) for v in row[1:]):
            raise ValueError('Invalid multiplier reference row')
    base.update(title='Powerball and Double Play reference prizes',
                basis='Separate game prize columns; jackpot advertisements are not individual payments.')
    exceptions = {'title': 'Power Play jackpot and five-white-ball exceptions',
        'rows': [['Match', 'Applies across Power Play multipliers']] + power['rows'][1:3],
        'basis': 'These source cells span all multiplier columns. Jackpot is not multiplied; five white balls has a fixed Power Play prize.'}
    power['rows'] = [power['rows'][0]] + power['rows'][3:]
    power.update(title='Power Play non-jackpot reference prizes',
        basis='10X is available only when the advertised annuity jackpot is $150 million or less. Power Play does not apply to Double Play.')
    return [base, exceptions, power]
