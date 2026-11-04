"""Reviewed linked rule prose, separate from results and winner statistics."""
import copy
import json
from datetime import datetime
from pathlib import Path

CONTRACTS = json.loads(Path(__file__).with_name('arizona_rule_detail_contracts.json').read_text())


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
                actualPayoutsAvailable=False)
