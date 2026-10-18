"""Source-labeled SD Winners; no unique-person, paid-claim or MM count inference."""
import json
from pathlib import Path
from tooling.south_dakota_draw_results import parse_results

SPEC = Path(__file__).with_name('south_dakota_report_specs.json')


def nonnegative(value):
    if type(value) is not int or value < 0:
        raise ValueError('Invalid source integer')
    return value


def parse_reports(payload, slug, *, now=None):
    results = parse_results(payload, slug, now=now)
    if slug == 'mega-millions':
        return [dict(drawId=r['drawId'], drawDate=r['drawDate'], game=r['game'],
                     variant=r['variant'], sourceUrl=r['sourceUrl'], tiers=[],
                     countUnit=None, limitation='Mega Millions count geography and multiplier units unresolved; counts excluded, not zero.')
                for r in results]
    expected = json.loads(SPEC.read_text())[slug]
    by_id = {r['id']:r for r in payload['draws'] if r['status']=='PAYABLE'}
    reports = []
    for result in results:
        source = by_id[result['drawId']]['prizeTiers']
        if not isinstance(source, list) or len(source) != len(expected):
            raise ValueError('Missing report tiers')
        tiers = []
        for tier, identity in zip(source, expected):
            if not isinstance(tier, dict) or {k:tier.get(k) for k in identity} != identity:
                raise ValueError('Changed report tier identity/order')
            option = slug in ('powerball-power-play','lotto-america')
            keys = {'shareCount','shareAmount','name','id','prizeType'} | ({'multiplierShareCount'} if option else set())
            if set(tier) != keys:
                raise ValueError('Changed source report fields')
            count = nonnegative(tier['shareCount'])
            amount = nonnegative(tier['shareAmount'])
            option_count = nonnegative(tier['multiplierShareCount']) if option else None
            dp = tier['name'].strip().endswith(' DP')
            if dp and option_count != 0:
                raise ValueError('Unexpected Double Play multiplier count')
            if dp != (result['variant']=='Double Play'):
                continue
            # Monetary zero is a source placeholder; never render a zero-dollar prize.
            # Preserve source cents/dollars distinction: shareAmount is dollars.
            amount_value = amount if amount > 0 else None
            if slug == 'millionaire-for-life' and tier['id'] in ('1','2'):
                label = '$1M/YEAR FOR LIFE' if tier['id']=='1' else '$100K/YEAR FOR LIFE'
                amount_value = None
            elif amount == 0:
                label = 'See literal prize schedule (source amount is a placeholder)'
            else:
                label = None
            if slug == 'xs-and-os':
                amount_value = None
                label = 'See literal prize schedule; official results omit prize amounts'
            tiers.append(dict(sourceTierId=tier['id'], match=tier['name'].strip(),
                              sdWinners=count, sdOptionWinners=option_count if option and not dp else None,
                              prizeAmountDollars=amount_value, prizeLabel=label))
        reports.append(dict(drawId=result['drawId'], drawDate=result['drawDate'],
                            game=result['game'], variant=result['variant'],
                            sourceUrl='https://lottery.sd.gov/winners/winning-numbers/',
                            countUnit='SD Winners (official source label; not unique people or paid claims)',
                            optionLabel=('Power Play' if slug=='powerball-power-play' else 'All Star Bonus')
                                        if option and result['variant']=='Regular' else None,
                            tiers=tiers))
    return reports
