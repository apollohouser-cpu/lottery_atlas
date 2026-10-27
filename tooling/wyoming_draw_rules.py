"""Reviewed literal Wyoming rule JSON and image-byte contracts.

Rule schedules are not dated payouts. Image transcription is tied to reviewed
bytes, never inferred from an image URL that may have changed in place.
"""
import copy
import hashlib
import json
from pathlib import Path

SPEC_PATH = Path(__file__).with_name('wyoming_rule_specs.json')


def parse_rules(payload, game, *, image_bytes=None):
    specs = json.loads(SPEC_PATH.read_text())
    if game not in specs:
        raise ValueError('Unsupported Wyoming rule game')
    if isinstance(payload, (bytes, str)):
        payload = json.loads(payload)
    spec = specs[game]
    if (not isinstance(payload, dict) or payload.get('status') != 'success'
            or payload.get('data') != {'rules': spec['rules']}):
        raise ValueError('Changed Wyoming rules require review')
    if 'image' in spec:
        if (not isinstance(image_bytes, bytes)
                or hashlib.sha256(image_bytes).hexdigest() != spec['image']['sha256']):
            raise ValueError('Changed/missing schedule image requires review')
    elif image_bytes is not None:
        raise ValueError('Unexpected Keno image')
    return {'game': game, 'sourceUrl': f'https://wyolotto.com/games/{game}',
            'coverage': 'Literal published schedules and rules, not dated payouts or winner counts.',
            **copy.deepcopy(spec)}
