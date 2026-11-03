"""Literal reviewed rule contracts; changed schedules/prose require fresh review."""
import copy
import json
from datetime import datetime
from pathlib import Path

CONTRACTS = json.loads(Path(__file__).with_name('arizona_rule_contracts.json').read_text())


def parse_capture(capture, game):
    if game not in CONTRACTS:
        raise ValueError('unreviewed rule family')
    if set(capture) != {'sourceUrl','captureKind','retrievedAt','tables','howToPlay'}:
        raise ValueError('rule capture fields changed')
    if capture['captureKind'] != 'browser-dom-rule-observation':
        raise ValueError('rule provenance mismatch')
    acquired = datetime.fromisoformat(capture['retrievedAt'].replace('Z','+00:00'))
    if acquired.tzinfo is None:
        raise ValueError('retrieval timezone required')
    contract = CONTRACTS[game]
    if any(capture[key] != value for key,value in contract.items()):
        raise ValueError('reviewed rule contract changed')
    return dict(game=game,sourceUrl=capture['sourceUrl'],retrievedAt=capture['retrievedAt'],
                captureKind=capture['captureKind'],tables=copy.deepcopy(capture['tables']),
                howToPlay=capture['howToPlay'],recordType='game-rules',
                actualPayoutsAvailable=False)
