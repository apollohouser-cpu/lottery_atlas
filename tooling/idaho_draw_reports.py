"""Dated Idaho-only source report counts; no distinct-ticket or cash inference."""
import re
from tooling.idaho_draw_results import parse_results


def _base(suffix):
    return [f'm5-{suffix}', 'm5', f'm4-{suffix}', 'm4', f'm3-{suffix}', 'm3', f'm2-{suffix}', f'm1-{suffix}', f'm0-{suffix}']


PB_BASE = _base('pb')
PB_PP = [key + '-pp' for key in PB_BASE[1:]]
LA_BASE = _base('sb')
LA_BONUS = [key + '-asb' for key in LA_BASE[1:]]
MM = ['m5-mb'] + [key + '-x' + str(m) for m in (2, 3, 4, 5, 10) for key in _base('mb')[1:]]
CONTRACTS = {
    'powerball': PB_BASE + PB_PP,
    'mega-millions': MM,
    'lotto-america': LA_BASE + LA_BONUS,
    'idaho-cash': ['Jackpot', '$200', '$5', 'Free Ticket'],
    'powerball-xs-os': ['m8', 'm7', 'm6', 'm5', 'm4'],
}


def _counts(rows, labels):
    if rows is None or rows == []:
        return None
    if not isinstance(rows, list) or len(rows) != len(labels):
        raise ValueError('Incomplete report tiers')
    result = []
    for row, label in zip(rows, labels):
        if not isinstance(row, dict) or row.get('0') != label:
            raise ValueError('Wrong or duplicate report tier identity')
        count = row.get('1')
        if type(count) is str:
            if not re.fullmatch(r'[0-9]+', count):
                raise ValueError('Malformed report count')
            count = int(count)
        if type(count) is not int or not 0 <= count <= 9007199254740991:
            raise ValueError('Invalid report count')
        result.append({'sourceTier': label, 'publishedWinnerCount': count})
    return result


def parse_reports(payload, slug, requested_date, *, as_of=None):
    results = parse_results(payload, slug, requested_date, as_of=as_of)
    if slug not in CONTRACTS:
        return [dict(group=r['group'], drawDate=requested_date, report=None,
                     gap='Pick report identity/unit review is incomplete; counts excluded.') for r in results]
    data = payload['data']
    rows = _counts(data.get('winners'), CONTRACTS[slug])

    def report(group, tiers, limitation):
        return dict(group=group, drawDate=requested_date,
                    report=None if tiers is None else dict(
                        sourceUrl=results[0]['sourceUrl'], sourceLabel='Idaho Winners',
                        countDefinition='Published Idaho prize-tier winner counts; distinct tickets and people are not established.',
                        tiers=tiers, limitation=limitation),
                    gap='No dated Idaho report rows supplied.' if tiers is None else None)

    if slug == 'powerball':
        return [report('powerball', None if rows is None else rows[9:],
                       'Power Play rows only. Undisplayed base counts and jackpot count excluded.'),
                report('powerball-double-play', _counts(data.get('winners_dp'), _base('dpb')),
                       'Double Play only; no Power Play multiplier.')]
    return [report(slug, rows, 'Source tier labels retained; no aggregate count or prize entitlement inferred.')]
