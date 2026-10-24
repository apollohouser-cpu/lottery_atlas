"""Prepare exact-date MFL report retention with original collection provenance.

Not wired into publication until client validation/display supports provenance.
Never treats the current page as evidence for an older report.
"""
import copy
from datetime import datetime
import re

SOURCE = 'https://www.idaholottery.com/games/draw/millionaire-for-life'
GAP = 'No exact-date Idaho HTML report available.'


def retain_mfl_report(old, candidate):
    result = copy.deepcopy(candidate)
    previous = {}
    for row in old['results']:
        key = (row['group'], row['drawDate'])
        if key in previous:
            raise ValueError('Duplicate prior result')
        previous[key] = row
    seen = set()
    for row in result['results']:
        key = (row['group'], row['drawDate'])
        if key in seen:
            raise ValueError('Duplicate candidate result')
        seen.add(key)
        if row['group'] != 'millionaire-for-life' or row['report'] is not None:
            continue
        before = previous.get(key)
        if before is None or before['report'] is None:
            continue
        # Only the known older-date omission is eligible, never a current result
        # outage, corrected result, or a different report-gap reason.
        latest = max(r['drawDate'] for r in result['results']
                     if r['group'] == 'millionaire-for-life')
        if row['drawDate'] >= latest or row['reportGap'] != GAP:
            raise ValueError('Ineligible report omission')
        a, b = copy.deepcopy(before), copy.deepcopy(row)
        for item in (a, b):
            for field in ('report', 'reportGap', 'reportProvenance'):
                item.pop(field, None)
        if a != b or row['sourceUrl'] != SOURCE:
            raise ValueError('Result correction during retention')
        report = before['report']
        if report['drawDate'] != row['drawDate'] or report['sourceUrl'] != SOURCE:
            raise ValueError('Retained report identity mismatch')
        if 'reportProvenance' in before:
            provenance = copy.deepcopy(before['reportProvenance'])
        else:
            matches = [e for e in old['sourceEvidence'] if e['url'] == SOURCE]
            if len(matches) != 1:
                raise ValueError('Missing/duplicate original source evidence')
            provenance = {'collectionStartedAt': old['collectionStartedAt'],
                          'sourceUrl': SOURCE, 'sha256': matches[0]['sha256']}
        if set(provenance) != {'collectionStartedAt', 'sourceUrl', 'sha256'}:
            raise ValueError('Malformed original provenance')
        stamp = datetime.fromisoformat(provenance['collectionStartedAt'])
        previous_stamp = datetime.fromisoformat(old['collectionStartedAt'])
        current_stamp = datetime.fromisoformat(candidate['collectionStartedAt'])
        if (stamp.tzinfo is None or previous_stamp.tzinfo is None or
                current_stamp.tzinfo is None or not stamp <= previous_stamp <= current_stamp or
                provenance['sourceUrl'] != SOURCE or
                not re.fullmatch('[0-9a-f]{64}', provenance['sha256'])):
            raise ValueError('Invalid original provenance')
        if 'reportProvenance' in row:
            raise ValueError('Unexpected provenance on missing candidate report')
        row['report'] = copy.deepcopy(report)
        row['reportGap'] = None
        row['reportProvenance'] = provenance
    return result


def check_report_provenance(old, candidate):
    """Validate each provenance addition against the actual prior snapshot.

    Existing provenance is immutable. Return a comparison copy with newly
    introduced provenance removed; all report content still faces continuity.
    """
    comparison = copy.deepcopy(candidate)
    prior = {(r['group'], r['drawDate']): r for r in old['results']}
    if len(prior) != len(old['results']):
        raise ValueError('Duplicate prior result')
    for row in comparison['results']:
        if 'reportProvenance' not in row:
            continue
        before = prior.get((row['group'], row['drawDate']))
        if before is None or before.get('report') is None:
            raise ValueError('Retention has no previously verified report')
        if 'reportProvenance' in before:
            if row['reportProvenance'] != before['reportProvenance']:
                raise ValueError('Original report provenance changed')
            continue
        missing = copy.deepcopy(candidate)
        target = next(r for r in missing['results']
                      if (r['group'], r['drawDate']) == (row['group'], row['drawDate']))
        target.pop('reportProvenance')
        target.update(report=None, reportGap=GAP)
        expected = retain_mfl_report(old, missing)
        retained = next(r for r in expected['results']
                        if (r['group'], r['drawDate']) == (row['group'], row['drawDate']))
        if row != retained:
            raise ValueError('Report/provenance does not match original evidence')
        row.pop('reportProvenance')
    return comparison
