"""Build a private CT candidate from hash-verified captures; no publication."""
import argparse
from datetime import date
import hashlib
import json
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

from tooling.connecticut_source_inventory import draw_inventory
from tooling.connecticut_draw_results import normalize, normalize_double_play
from tooling.connecticut_cash5_report import parse as cash5_report


def verified_capture(root, filename, manifest):
    raw = (root / filename).read_bytes()
    if not raw or len(raw) != manifest.get('bytes') or hashlib.sha256(raw).hexdigest() != manifest.get('sha256'):
        raise ValueError('Source capture size/hash mismatch: ' + filename)
    return raw


def build(root, observed_date):
    manifest = json.loads((root / 'capture.json').read_text())
    if manifest.get('url') != 'https://ctlottery.com/':
        raise ValueError('Unexpected result source')
    raw = verified_capture(root, 'home.html', manifest)
    games = draw_inventory(raw.decode('utf-8'))
    results = []
    for index, game in enumerate(games):
        results.extend(normalize(game, observed_date))
        if game['apiSlug'] == 'powerball':
            results.append(normalize_double_play(game, observed_date, inventory_index=index))
    identities = [(r['game'], r.get('session', '')) for r in results]
    if len(results) != 12 or len(set(identities)) != 12:
        raise ValueError('Incomplete or duplicate result groups')
    source_game = next(g for g in games if g['apiSlug'] == 'cash5')
    source_draw = source_game['payouts'][0]['draw']
    draw_id = source_draw.get('drawId')
    if not isinstance(draw_id, str) or not draw_id.isdigit() or int(draw_id) <= 0:
        raise ValueError('Invalid captured Cash5 draw ID')
    report_manifest = json.loads((root / 'cash5_payout_manifest.json').read_text())
    url = urlsplit(report_manifest.get('url', ''))
    expected = {'game': ['cash5'], 'draw': [draw_id], 'date': [source_draw['drawDate']]}
    if (url.scheme != 'https' or url.netloc != 'ctlottery.com' or
            url.path != '/api/winning-payouts' or url.fragment or
            parse_qs(url.query, strict_parsing=True) != expected):
        raise ValueError('Payout request does not match captured result')
    report_raw = verified_capture(root, 'cash5_payout.json', report_manifest)
    report = cash5_report(json.loads(report_raw), draw_id=int(draw_id),
                          draw_date=source_draw['drawDate'], observed_date=observed_date)
    return {'schemaVersion': 1, 'stateCode': 'CT', 'productionReady': False,
            'recordType': 'private development candidate',
            'observedDate': observed_date.isoformat(), 'draws': results,
            'reports': [report], 'evidence': [manifest, report_manifest],
            'limitations': ['Captured snapshots, not a current live feed or complete history.',
                'Not yet packaged, bundled, cached or verified in the physical app.',
                'Other payout reports and prize/rule integration remain unfinished.',
                'No geographic activity or statewide distinct-ticket totals inferred.']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--observed-date', type=date.fromisoformat, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    candidate = build(args.evidence, args.observed_date)
    # Exclusive creation prevents accidental replacement of prior reviewed bytes.
    with args.output.open('x') as stream:
        json.dump(candidate, stream, indent=2, allow_nan=False)
        stream.write('\n')
    print(f"Private candidate: {len(candidate['draws'])} result groups, {len(candidate['reports'])} report")


if __name__ == '__main__':
    main()
