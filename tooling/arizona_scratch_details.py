"""Validate rendered Scratchers tiers, without treating remaining prizes as stock."""
import copy
import re
from datetime import datetime
from decimal import Decimal


def parse_capture(capture, expected_url, expected_header):
    if set(capture) != {'sourceUrl','captureKind','retrievedAt','header','table','rules','prizeDetails'}:
        raise ValueError('scratcher capture fields changed')
    if capture['sourceUrl'] != expected_url or capture['captureKind'] != 'browser-dom-scratcher-detail-observation':
        raise ValueError('scratcher provenance mismatch')
    if datetime.fromisoformat(capture['retrievedAt'].replace('Z','+00:00')).tzinfo is None:
        raise ValueError('retrieval timezone required')
    if capture['header'] != expected_header:
        raise ValueError('reviewed product header changed')
    lines=[s for s in capture['table'].splitlines() if s.strip()]
    if not lines or lines.pop(0) != 'Prize\tOdds 1 In\tPrizes Remaining':
        raise ValueError('tier columns changed')
    overall=re.fullmatch(r'Overall Odds: 1 in ([0-9]+(?:\.[0-9]+)?)',lines.pop() if lines else '')
    if not overall or Decimal(overall[1]) < 1 or not lines:
        raise ValueError('missing tiers or invalid overall odds')
    tiers=[];seen=set()
    for line in lines:
        parts=line.split('\t')
        if len(parts)!=3 or not parts[0].startswith('$') or parts[0] in seen:
            raise ValueError('invalid or duplicate prize tier')
        seen.add(parts[0])
        numeric=r'(?:[0-9]+|[1-9][0-9]{0,2}(?:,[0-9]{3})+)'
        if not re.fullmatch(numeric+r'(?:\.[0-9]+)?',parts[1]):
            raise ValueError('invalid odds')
        odds=Decimal(parts[1].replace(',',''))
        counts=re.fullmatch('('+numeric+') of ('+numeric+')',parts[2])
        if not counts or odds < 1:
            raise ValueError('invalid remaining prize counts')
        remaining,total=(int(v.replace(',','')) for v in counts.groups())
        if total < 1 or remaining > total:
            raise ValueError('remaining exceeds original prizes')
        tiers.append(dict(prizeLabel=parts[0],oddsOneIn=parts[1],remainingPrizes=remaining,originalPrizes=total))
    return dict(sourceUrl=expected_url,retrievedAt=capture['retrievedAt'],tiers=tiers,
                overallOddsOneIn=overall[1],rules=copy.deepcopy(capture['rules']),
                prizeDetails=capture['prizeDetails'],inventoryAvailable=False,
                symbolInterpretationAvailable=False)
