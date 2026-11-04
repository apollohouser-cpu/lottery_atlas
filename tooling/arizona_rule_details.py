"""Reviewed linked rule prose, separate from results and winner statistics."""
import copy
import json
from datetime import datetime
from pathlib import Path

CONTRACTS = json.loads(Path(__file__).with_name('arizona_rule_detail_contracts.json').read_text())
SOURCE_CONFLICTS = {
    'hi-lo': [
        'Linked Hi-Lo instructions refer to a two-digit number and a Two to '
        'Win claim heading. These labels are preserved literally; they do '
        'not change the Hi-Lo count model or identify a Two to Win source.'
    ],
    'triple-twist': [
        'Sales cutoff unresolved: the product page states 6:59 PM Arizona '
        'time; linked details state seasonal 6:59/7:59 PM. Neither is '
        'selected as a normalized cutoff.'
    ],
    'pick-4': [
        'Box 24-Way wording conflicts: the player tip says all four digits '
        'differ, while the Box 24-Way paragraph says two differ. Preserve both; '
        'do not normalize the latter into a matching algorithm.',
        'The Pick 4 FAQ odds link points to Pick 3. It is retained as source '
        'evidence, not treated as a Pick 4 odds source.'
    ],
    'powerball-xs-os': [
        'Sales cutoff unresolved: the product page states 5:59/6:59 PM Arizona '
        'time seasonally; the linked details state 8:59/9:59 PM. Neither is '
        'selected as a normalized cutoff.'
    ]
}


def parse_capture(capture, game):
    if game not in CONTRACTS:
        raise ValueError('unreviewed rule detail family')
    if set(capture) != {'sourceUrl', 'captureKind', 'retrievedAt', 'title', 'sections'}:
        raise ValueError('rule detail fields changed')
    if capture['captureKind'] != 'browser-dom-rule-detail-observation':
        raise ValueError('rule detail provenance mismatch')
    acquired = datetime.fromisoformat(capture['retrievedAt'].replace('Z', '+00:00'))
    if acquired.tzinfo is None:
        raise ValueError('retrieval timezone required')
    if any(capture[key] != value for key, value in CONTRACTS[game].items()):
        raise ValueError('reviewed rule detail changed')
    return dict(game=game, **copy.deepcopy(capture), recordType='game-rule-details',
                actualPayoutsAvailable=False,
                sourceConflicts=copy.deepcopy(SOURCE_CONFLICTS.get(game, [])))
