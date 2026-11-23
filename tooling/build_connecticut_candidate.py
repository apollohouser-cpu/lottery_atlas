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
from tooling.connecticut_state_reports import parse as state_report
from tooling.connecticut_powerball_report import parse as powerball_report
from tooling.connecticut_play_reports import parse as play_report
from tooling.connecticut_rule_links import RULE_NAMES, extract as rule_links
from tooling.connecticut_scratch_package import package as package_scratch
from tooling.connecticut_keno_prizes import parse as keno_prizes
from tooling.connecticut_prize_references import CONFIG as PRIZE_GAMES, parse as prize_references


def verified_capture(root, filename, manifest):
    raw = (root / filename).read_bytes()
    if not raw or len(raw) != manifest.get('bytes') or hashlib.sha256(raw).hexdigest() != manifest.get('sha256'):
        raise ValueError('Source capture size/hash mismatch: ' + filename)
    return raw


def verify_report_request(manifest, game, source_draw):
    draw_id = source_draw.get('drawId')
    if not isinstance(draw_id, str) or not draw_id.isdigit() or int(draw_id) <= 0:
        raise ValueError('Invalid captured draw ID')
    draw_date = source_draw.get('drawDate')
    if not isinstance(draw_date, str):
        raise ValueError('Missing source draw date')
    url = urlsplit(manifest.get('url', ''))
    expected = {'game': [game], 'draw': [draw_id], 'date': [draw_date]}
    if (url.scheme != 'https' or url.netloc != 'ctlottery.com' or
            url.path != '/api/winning-payouts' or url.fragment or
            parse_qs(url.query, strict_parsing=True) != expected):
        raise ValueError('Payout request does not match captured result')
    return int(draw_id), draw_date


def build(root, observed_date, scratch_raw=None, scratch_sha256=None):
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
    report_manifests = [dict(json.loads((root / 'cash5_payout_manifest.json').read_text()), game='cash5')]
    extra = json.loads((root / 'additional_payout_manifest.json').read_text())
    if not isinstance(extra, list) or len(extra) != 3 or {m.get('game') for m in extra} != {'lotto', 'mfl', 'xsandos'}:
        raise ValueError('Incomplete or duplicate additional report evidence')
    report_manifests.extend(extra)
    remaining = json.loads((root / 'remaining_payout_manifest.json').read_text())
    expected_remaining = {'powerball', 'megamillions', 'play3day', 'play3night', 'play4day', 'play4night'}
    if (not isinstance(remaining, list) or len(remaining) != 6 or
            {m.get('game') for m in remaining} != expected_remaining or
            any(m.get('ok') is not True for m in remaining)):
        raise ValueError('Incomplete remaining report evidence')
    report_manifests.extend(m for m in remaining if m['game'] != 'megamillions')
    reports = []
    for report_manifest in report_manifests:
        game = report_manifest['game']
        matches = [p['draw'] for g in games for p in g.get('payouts', []) if p.get('apiGame') == game]
        if len(matches) != 1:
            raise ValueError('Missing or ambiguous report result binding')
        source_draw = matches[0]
        draw_id, draw_date = verify_report_request(report_manifest, game, source_draw)
        report_raw = verified_capture(root, game + '_payout.json', report_manifest)
        kwargs = dict(draw_id=draw_id, draw_date=draw_date, observed_date=observed_date)
        payload = json.loads(report_raw)
        if game == 'cash5': report = cash5_report(payload, **kwargs)
        elif game == 'powerball': report = powerball_report(payload, **kwargs)
        elif game.startswith(('play3', 'play4')): report = play_report(payload, game=game, **kwargs)
        else: report = state_report(payload, game=game, **kwargs)
        reports.append(report)
    details = json.loads((root / 'detail_captures.json').read_text())
    if (not isinstance(details, list) or len(details) != len(RULE_NAMES) or
            {d.get('game') for d in details} != set(RULE_NAMES)):
        raise ValueError('Incomplete rule-link source evidence')
    summaries = json.loads(Path(__file__).with_name('connecticut_rule_summaries.json').read_text())
    references = []
    for detail in details:
        game = detail['game']
        expected_url = next(r['sourceUrl'] for r in results if r['game'] == game)
        if detail.get('ok') is not True or detail.get('url') != expected_url:
            raise ValueError('Rule-link source does not match game')
        html = verified_capture(root, game + '.html', detail).decode('utf-8')
        summary = summaries[game]
        if (summary['sourceCaptureSha256'] != detail['sha256'] or
                summary['sourceUrl'] != expected_url):
            raise ValueError('Rule summary requires review against changed source')
        references.append(dict(rule_links(html, game),
                               notes=summary['notes'],
                               prizeTables=(keno_prizes(html) if game == 'keno' else
                                            prize_references(html, game) if game in PRIZE_GAMES else []),
                               observedOnSourceUrl=expected_url,
                               sourceCaptureSha256=detail['sha256']))
    candidate = {'schemaVersion': 1, 'stateCode': 'CT', 'productionReady': False,
            'recordType': 'private development candidate',
            'observedDate': observed_date.isoformat(), 'draws': results,
            'reports': reports, 'ruleReferences': references,
            'evidence': [manifest] + report_manifests + details,
            'limitations': ['Captured snapshots, not a current live feed or complete history.',
                'Not yet packaged, bundled, cached or verified in the physical app.',
                'Mega Millions payout counts withheld: aggregate/multiplier discrepancy unresolved.',
                'Prize/rule integration remains unfinished.',
                'No geographic activity or statewide distinct-ticket totals inferred.']}

    if scratch_raw is not None or scratch_sha256 is not None:
        candidate['scratchCatalog'] = package_scratch(scratch_raw, scratch_sha256, observed_date)
        candidate['scratchCatalogSha256'] = scratch_sha256
    return candidate


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--observed-date', type=date.fromisoformat, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--scratch-catalog', type=Path, required=True)
    parser.add_argument('--scratch-sha256', required=True)
    args = parser.parse_args()
    candidate = build(args.evidence, args.observed_date, args.scratch_catalog.read_bytes(), args.scratch_sha256)
    # Exclusive creation prevents accidental replacement of prior reviewed bytes.
    with args.output.open('x') as stream:
        json.dump(candidate, stream, indent=2, allow_nan=False)
        stream.write('\n')
    print(f"Private candidate: {len(candidate['draws'])} result groups, {len(candidate['reports'])} report")


if __name__ == '__main__':
    main()
