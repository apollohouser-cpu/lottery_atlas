"""Compose retained Delaware sources into a private, explicitly incomplete candidate."""
import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
from tooling.build_delaware_draw_candidate import build as build_draws
from tooling.build_delaware_rule_candidate import build as build_rules
from tooling.build_delaware_report_candidate import build as build_reports
from tooling.validate_delaware_instant_evidence import validate as validate_images
from tooling.delaware_instant_instructions import compose as compose_instructions
from tooling.delaware_instant_tiers import compose as compose_tiers
from tooling.import_delaware_scratch_catalog import parse_catalog, parse_report, parse_closeouts, join


def read_opening(root):
    entries = json.loads((root / 'opening-manifest.json').read_text())
    by_name = {e['name']: e for e in entries}
    if len(entries) != len(by_name):
        raise ValueError('Duplicate opening source')
    raw, evidence = {}, {}
    expected = {'instant': 'https://www.delottery.com/Instant-Games',
                'top-prizes': 'https://www.delottery.com/Instant-Games/Top-Prizes-Remaining',
                'closeout': 'https://www.delottery.com/Instant-Games/Close-Out-Schedule'}
    for name, url in expected.items():
        e = by_name[name]
        content = (root / (name + '.html')).read_bytes()
        stamp = datetime.fromisoformat(e['retrievedAt'])
        if stamp.tzinfo is None or e['url'] != url or e['status'] != 200:
            raise ValueError('Invalid opening source identity/time/status')
        if len(content) != e['bytes'] or hashlib.sha256(content).hexdigest() != e['sha256']:
            raise ValueError('Opening source bytes changed')
        raw[name] = content
        evidence[name] = {k: e[k] for k in ('url', 'retrievedAt', 'bytes', 'sha256')}
    return raw, evidence


def build(root):
    raw, evidence = read_opening(root)
    catalog = parse_catalog(raw['instant'])
    stamp, report = parse_report(raw['top-prizes'])
    closeouts = parse_closeouts(raw['closeout'])
    observed = datetime.fromisoformat(evidence['instant']['retrievedAt']).date()
    products = join(catalog, stamp, report, closeouts, observed)
    images = validate_images(root / 'instant.html', root / 'instant_details_20261107_encoded')
    draws, rules = build_draws(root), build_rules(root)
    return {
        'stateCode': 'DE', 'schemaVersion': 1, 'productionReady': False,
        'recordType': 'incomplete-development-candidate',
        'draws': draws, 'rules': rules, 'products': products,
        'publishedReports': build_reports(root),
        'productEvidence': evidence, 'detailImages': images,
        'reviewedInstantPrizeStructures': compose_tiers(images),
        'instantInstructions': compose_instructions(
            json.loads((root / 'instant-instruction-screen-index.json').read_text()), images),
        'closeouts': [{'gameId': gid, 'dateLaunched': value['start'].isoformat(),
                      'announcedEndOfSales': value['end'].isoformat()}
                     for gid, value in sorted(closeouts.items(), key=lambda item: int(item[0]))],
        'limitations': [
            'Retained opening observations only; composition is not a new source collection.',
            'Instant detail image integrity verified; complete semantic transcription remains pending.',
            'Printed prize structures, remaining top prizes, and actual claims are distinct.',
            'Game528 printed count excludes its second-chance trip while printed value includes it; no combined Scratch-only summary is published.',
            'Qualified source reports are separate from draw results; remaining report conflicts and unit uncertainty are disclosed.',
            'No retailer inventory, geographic wins, complete history or production acceptance.',
        ],
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = build(args.evidence)
    with args.output.open('x') as target:
        json.dump(result, target, indent=2)
        target.write('\n')
    print(f"Private candidate: {result['draws']['selectedRows']} results, "
          f"{result['rules']['families']} rule families, {len(result['products']['games'])} catalog entries; not production ready.")
