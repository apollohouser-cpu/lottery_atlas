"""Reviewed literal Sum It Up rows, accepted only for exact source image bytes."""
import copy
import hashlib
import json
from pathlib import Path

SPECS = json.loads(Path(__file__).with_name('idaho_sum_specs.json').read_text())


def parse_schedule(game, raw):
    if game not in SPECS:
        raise ValueError('Unsupported Sum It Up game')
    spec = SPECS[game]
    if hashlib.sha256(raw).hexdigest() != spec['sha256']:
        raise ValueError('Unreviewed Sum It Up image')
    return copy.deepcopy(spec)
