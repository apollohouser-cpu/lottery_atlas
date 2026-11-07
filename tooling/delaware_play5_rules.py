"""Hash-bound visual chart transcription; changed images require a new audit."""
import hashlib
import json
from pathlib import Path


def parse(chart_bytes, *, chart_url):
    rules = json.loads(Path(__file__).with_name('delaware_play5_chart.json').read_text())
    if chart_url != rules['chartUrl'] or hashlib.sha256(chart_bytes).hexdigest() != rules['chartSha256']:
        raise ValueError('Play 5 chart changed; visual re-audit required')
    return rules
