"""Bounded Fast Play detail parsing; progressive value is an observation only."""
import copy
import re
from arizona_scratch_details import parse_capture as parse_tiers


def parse_capture(capture, baseline):
    if set(capture) != set(baseline) or 'faq' not in capture:
        raise ValueError('Fast Play capture fields changed')
    if capture['faq'] != baseline['faq'] or capture['rules'] != baseline['rules']:
        raise ValueError('Fast Play rules or claim restrictions changed')
    header=capture['header']
    old=baseline['header']
    pattern=r'PROGRESSIVE JACKPOT: (\$[0-9]{1,3}(?:,[0-9]{3})*|\$[0-9]+)'
    match=re.search(pattern,header)
    if not match or re.sub(pattern,'PROGRESSIVE JACKPOT: <observed>',header) != re.sub(pattern,'PROGRESSIVE JACKPOT: <observed>',old):
        raise ValueError('Fast Play identity or loaded jackpot changed shape')
    stripped={k:v for k,v in capture.items() if k!='faq'}
    result=parse_tiers(stripped,baseline['sourceUrl'],header,kind='fast-play',extra_prize_labels=('Progressive',))
    if sum(t['prizeLabel']=='Progressive' for t in result['tiers']) != 1:
        raise ValueError('missing progressive tier')
    result.update(faq=copy.deepcopy(capture['faq']),progressiveJackpotObserved=match[1],
                  progressiveJackpotGuaranteed=False)
    return result
