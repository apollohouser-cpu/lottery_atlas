"""Return reviewed literal Iowa chart rows only when exact source bytes match."""
import hashlib
import json
from copy import deepcopy
from pathlib import Path

SPECS = json.loads(Path(__file__).with_name('iowa_schedule_specs.json').read_text())['schedules']

def verified_chart(game, raw):
    matches = [s for s in SPECS if s['game'] == game]
    if len(matches) != 1 or not isinstance(raw, bytes):
        raise ValueError('Unknown chart or invalid bytes')
    spec = matches[0]
    if hashlib.sha256(raw).hexdigest() != spec['sha256']:
        raise ValueError('Chart changed; visual review required')
    return deepcopy(spec)
