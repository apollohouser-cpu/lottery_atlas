"""Audited image schedules: fail closed on changed bytes or source identity."""
import hashlib
import json
from pathlib import Path


def parse(chart_bytes, *, chart_url, digits):
    if type(digits) is not int or digits not in (3, 4, 5):
        raise ValueError('Unsupported Play game')
    rules = json.loads(Path(__file__).with_name(f'delaware_play{digits}_chart.json').read_text())
    if chart_url != rules['chartUrl'] or hashlib.sha256(chart_bytes).hexdigest() != rules['chartSha256']:
        raise ValueError(f'Play {digits} chart changed; visual re-audit required')
    return rules
