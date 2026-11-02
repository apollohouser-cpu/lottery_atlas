"""All nineteen Arizona draw groups; internal validation, not a public feed.

Inputs are retained DOM captures, not evidence of an atomic source collection.
No missing source is substituted and no persistence is performed here.
"""
from tooling.arizona_regular_draws import select_refresh as regular_refresh
from tooling.arizona_quick_draw import select_refresh as hourly_refresh


def select_refresh(candidate, retained):
    for bundle in (candidate, retained):
        if not isinstance(bundle, dict) or set(bundle) != {'regular', 'quickDraw'}:
            raise ValueError('regular and Quick Draw captures required')
    regular = regular_refresh(candidate['regular'], retained['regular'])
    hourly = hourly_refresh(candidate['quickDraw'], retained['quickDraw'])
    if set(regular['groups']) & set(hourly['groups']):
        raise ValueError('duplicate draw group')
    groups = {**regular['groups'], **hourly['groups']}
    if len(groups) != 19 or any(len(rows) != 2 for rows in groups.values()):
        raise ValueError('nineteen two-result groups required')
    provenance = {game: [entry] for game, entry in regular['provenance'].items()}
    provenance.update(hourly['provenance'])
    for game, rows in groups.items():
        sources = {entry['sourceUrl'] for entry in provenance[game]}
        if any(row['sourceUrl'] not in sources or row['reportStatus'] != 'unavailable' for row in rows):
            raise ValueError('unreviewed source or report status')
    return {'groups': groups, 'provenance': provenance}
