"""Compose qualified source reports separately from draw rows and map activity."""
from datetime import datetime
import hashlib
import json
from tooling import delaware_multiwin_report as multiwin
from tooling import delaware_xsos_report as xsos
from tooling import delaware_play_report as play
from tooling import delaware_luckyforlife_report as legacy
from tooling import delaware_doubleplay_report as doubleplay

TARGETS = [('Multi-Win-Lotto', multiwin), ('Powerball-Xs-And-Os', xsos),
           ('Powerball', doubleplay), ('Play-3', play), ('Play-4', play), ('Play-5', play), ('Lucky-For-Life', legacy)]


def build(root):
    entries = json.loads((root / 'rules-history-manifest.json').read_text())
    by_file = {e['file']: e for e in entries}
    if len(by_file) != len(entries):
        raise ValueError('Ambiguous report evidence')
    reports = []
    for slug, module in TARGETS:
        filename = f'Drawing-Games_{slug}_Number-Of-Winners.html'
        entry = by_file[filename]
        expected = f'https://www.delottery.com/Drawing-Games/{slug}/Number-Of-Winners'
        stamp = datetime.fromisoformat(entry['retrievedAt'])
        raw = (root / filename).read_bytes()
        if entry['url'] != expected or entry['status'] != 200 or stamp.tzinfo is None:
            raise ValueError('Invalid report source/status/time')
        if len(raw) != entry['bytes'] or hashlib.sha256(raw).hexdigest() != entry['sha256']:
            raise ValueError('Report evidence changed')
        kwargs = {'source_url': expected, 'observed_date': stamp.date()}
        if slug.startswith('Play-'):
            kwargs['digits'] = int(slug[-1])
        parsed = module.parse(raw.decode("utf-8"), **kwargs)
        family = 'Powerball-Double-Play' if module is doubleplay else slug
        reports.append({'family': family, 'report': parsed,
                        'evidence': {k: entry[k] for k in ['url', 'retrievedAt', 'bytes', 'sha256']}})
    return {
        'status': 'private qualified report candidate; not a map activity feed',
        'reports': reports,
        'limitations': [
            'Source category counts remain literal; no cross-category sums or unique-person/ticket totals inferred.',
            'Report dates and sessions are independent of selected latest draw rows; no automatic attachment to another drawing.',
            'Lucky For Life reports are historical/legacy, not evidence of current operation.',
            'Lotto America and base Powerball/Power Play grouped-header conflicts remain unresolved. Only the independent Double Play table is integrated from the Powerball page; Mega Millions reports remain unintegrated.',
            'No within-state win locations, retailer joins or derived payout amounts.',
        ],
    }
