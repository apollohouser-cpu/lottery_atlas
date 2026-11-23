"""CT digit-game payout presentation: overlapping source groups, winning plays."""
from datetime import date
import json
from pathlib import Path
import re


def parse(payload, *, game, draw_id, draw_date, observed_date):
    match = re.fullmatch(r'(play[34])(day|night)', game)
    if not match or type(draw_id) is not int or draw_id <= 0:
        raise ValueError('Invalid game/session or draw identity')
    product, session = match.groups()
    if not isinstance(draw_date, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', draw_date):
        raise ValueError('Missing explicit result date')
    if date.fromisoformat(draw_date) > observed_date:
        raise ValueError('Future draw date')
    if (payload.get('game') != game or type(payload.get('draw')) is not int or
            payload['draw'] != draw_id or payload.get('drawFound') is not True):
        raise ValueError('Report/session mismatch')
    counts = payload.get('counts')
    keys = {str(n) for n in range(1, (24 if product == 'play3' else 40)+1)}
    if not isinstance(counts, dict) or set(counts) != keys:
        raise ValueError('Missing or changed source count tiers')
    if any(type(n) is not int or n < 0 for n in counts.values()):
        raise ValueError('Invalid source play count')
    config = json.loads(Path(__file__).with_name('connecticut_play_report_tiers.json').read_text())
    tiers = config['games'][product]
    if {str(n) for t in tiers for n in t['sourceTiers']} != keys:
        raise ValueError('Incomplete reviewed tier mapping')
    rows = [dict(match=t['match'], sourceTiers=t['sourceTiers'],
                 reportedWinningPlays=sum(counts[str(n)] for n in t['sourceTiers']),
                 minimumWagerPrizeLabel=t['minimumWagerPrizeLabel']) for t in tiers]
    return dict(game=product, session=session.title(), drawId=draw_id, drawDate=draw_date,
                dateEvidence='Audited session result and request date; response echoes draw ID only',
                countLabel='Winning Plays', rows=rows,
                sourceUrl=f'https://ctlottery.com/api/winning-payouts?game={game}&draw={draw_id}&date={draw_date}',
                limitations=[config['note'], 'Not distinct-ticket counts or retailer activity.',
                             'Prize labels are minimum-wager reference values, not individual payouts.'])
