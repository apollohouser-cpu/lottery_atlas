"""Historical chart; source identity never implies current operation."""
import hashlib
import json
from pathlib import Path


def parse(chart_bytes, *, chart_url):
    rules = json.loads(Path(__file__).with_name('delaware_luckyforlife_chart.json').read_text())
    if chart_url != rules['chartUrl'] or hashlib.sha256(chart_bytes).hexdigest() != rules['chartSha256']:
        raise ValueError('Legacy chart changed; visual re-audit required')
    return rules
