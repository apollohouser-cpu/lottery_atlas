"""Join manually reviewed instructions to independently validated image evidence.

Only instructions and qualifications are composed. Printed run totals and partially
transcribed tier tables are deliberately not promoted by this contract.
"""
from datetime import datetime


def compose(index, images):
    if index.get('completeInstructionScreen') is not True or index.get('completeTierAudit') is not False:
        raise ValueError('Unexpected instruction/tier review scope')
    reviewed = datetime.fromisoformat(index['reviewedAt'])
    if reviewed.tzinfo is None:
        raise ValueError('Review timestamp requires timezone')
    expected = {x['gameId']: x for x in images}
    if len(expected) != len(images) or not expected:
        raise ValueError('Invalid validated image identities')
    entries = index['entries']
    if type(index.get('count')) is not int or index['count'] != len(entries):
        raise ValueError('Review count mismatch')
    seen, result = set(), []
    for entry in entries:
        gid = entry['gameId']
        if gid in seen or gid not in expected:
            raise ValueError('Duplicate or unknown reviewed identity')
        seen.add(gid)
        source = expected[gid]
        for key, image_key in [('sourceUrl', 'sourceUrl'), ('sourceRetrievedAt', 'retrievedAt'),
                               ('sourceSha256', 'sha256')]:
            if entry.get(key) != source[image_key]:
                raise ValueError('Reviewed image provenance mismatch')
        acquired = datetime.fromisoformat(source['retrievedAt'])
        if acquired.tzinfo is None or reviewed < acquired:
            raise ValueError('Review predates source acquisition')
        for key in ('instructionSummary', 'boundary', 'review'):
            if not isinstance(entry.get(key), str) or not entry[key].strip():
                raise ValueError('Missing instruction or review boundary')
        qualifications = []
        for key in ('caveat', 'valuationCaveat'):
            if key in entry:
                if not isinstance(entry[key], str) or not entry[key].strip():
                    raise ValueError('Invalid qualification')
                qualifications.append(entry[key])
        result.append({'gameId': gid, 'names': source['names'],
                       'sourceUrl': source['sourceUrl'], 'sourceRetrievedAt': source['retrievedAt'],
                       'sourceSha256': source['sha256'], 'instructionSummary': entry['instructionSummary'],
                       'boundary': entry['boundary'], 'qualifications': qualifications,
                       'tierCoverage': 'not-complete', 'reviewedAt': index['reviewedAt']})
    if seen != set(expected):
        raise ValueError('Incomplete instruction coverage')
    return sorted(result, key=lambda x: int(x['gameId']))
