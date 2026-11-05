"""Validate rendered Scratchers tiers, without treating remaining prizes as stock."""
import copy
import re
from datetime import datetime
from decimal import Decimal


def parse_capture(capture, expected_url, expected_header, *, kind="scratcher", extra_prize_labels=(), overall_label="Overall Odds"):
    if set(capture) != {'sourceUrl','captureKind','retrievedAt','header','table','rules','prizeDetails'}:
        raise ValueError('scratcher capture fields changed')
    if capture['sourceUrl'] != expected_url or capture['captureKind'] != f'browser-dom-{kind}-detail-observation':
        raise ValueError('scratcher provenance mismatch')
    if datetime.fromisoformat(capture['retrievedAt'].replace('Z','+00:00')).tzinfo is None:
        raise ValueError('retrieval timezone required')
    if capture['header'] != expected_header:
        raise ValueError('reviewed product header changed')
    lines=[s.strip() for s in capture['table'].splitlines() if s.strip()]
    if not lines or lines.pop(0) != 'Prize\tOdds 1 In\tPrizes Remaining':
        raise ValueError('tier columns changed')
    overall=re.fullmatch(re.escape(overall_label)+r': 1 in ([0-9]+(?:\.[0-9]+)?)',lines.pop() if lines else '')
    if not overall or Decimal(overall[1]) < 1 or not lines:
        raise ValueError('missing tiers or invalid overall odds')
    tiers=[];seen=set()
    for line in lines:
        parts=line.split('\t')
        if len(parts)!=3 or (not parts[0].startswith('$') and parts[0] not in extra_prize_labels) or parts[0] in seen:
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


def validate_continuity(capture, baseline, *, kind="scratcher", extra_prize_labels=(), overall_label="Overall Odds"):
    """Gate repeat observations; corrections need explicit review, not silent adoption."""
    old=parse_capture(baseline,baseline['sourceUrl'],baseline['header'],kind=kind,extra_prize_labels=extra_prize_labels,overall_label=overall_label)
    new=parse_capture(capture,baseline['sourceUrl'],baseline['header'],kind=kind,extra_prize_labels=extra_prize_labels,overall_label=overall_label)
    if datetime.fromisoformat(new['retrievedAt'].replace('Z','+00:00')) < datetime.fromisoformat(old['retrievedAt'].replace('Z','+00:00')):
        raise ValueError('retrieval date regressed')
    if new['rules'] != old['rules'] or new['overallOddsOneIn'] != old['overallOddsOneIn']:
        raise ValueError('rules or overall odds changed; review required')
    def caveat(c):
        if c['prizeDetails'].count(c['table']) != 1:
            raise ValueError('tier table and detail observation disagree')
        return c['prizeDetails'].replace(c['table'],'',1).strip()
    if caveat(capture) != caveat(baseline):
        raise ValueError('prize terms changed; review required')
    if len(new['tiers']) != len(old['tiers']):
        raise ValueError('tier set changed')
    for current,previous in zip(new['tiers'],old['tiers']):
        if any(current[k] != previous[k] for k in ('prizeLabel','oddsOneIn','originalPrizes')):
            raise ValueError('tier identity or original structure changed')
        if current['remainingPrizes'] > previous['remainingPrizes']:
            raise ValueError('remaining prize increase requires review')
    return new
