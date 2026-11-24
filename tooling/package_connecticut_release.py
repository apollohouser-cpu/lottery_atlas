"""Prepare reviewed CT release bytes; never publish or mark state accepted."""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import urlsplit

PUBLIC_FIELDS = ('schemaVersion', 'stateCode', 'observedDate', 'draws', 'reports',
                 'ruleReferences', 'scratchCatalog', 'scratchCatalogSha256')
LIMITATIONS = [
    'Retained source snapshots, not a live feed or complete history. Each observation keeps its original source date.',
    'No complete all-tier claims, verified selling-location activity or statewide distinct-ticket totals established.',
    'Mega Millions payout counts withheld: aggregate and multiplier breakdown do not reconcile.',
    'Life-prize API amounts with unverified meaning are withheld; annual prize labels are not cash amounts or lifetime totals.',
    'Scratch game 1725 excluded due to conflicting cash values. Remaining prizes are not store stock or dated claims.',
    'Reference prize schedules and multiplier frequencies are not actual payouts or winning-ticket counts. Source rule PDFs require internet access.',
    'Fast Play is limited to an official rules route. Historical games and promotional awards are not a complete results archive.',
]


def package(raw, reviewed_sha256):
    if hashlib.sha256(raw).hexdigest() != reviewed_sha256:
        raise ValueError('Candidate differs from reviewed bytes')
    candidate = json.loads(raw)
    if (candidate.get('stateCode') != 'CT' or candidate.get('schemaVersion') != 1 or
            candidate.get('productionReady') is not False or
            candidate.get('recordType') != 'private development candidate'):
        raise ValueError('Unexpected candidate identity')
    if (len(candidate.get('draws', [])) != 12 or len(candidate.get('reports', [])) != 9 or
            len(candidate.get('ruleReferences', [])) != 9 or not candidate.get('scratchCatalog')):
        raise ValueError('Incomplete reviewed coverage')
    result = {key: candidate[key] for key in PUBLIC_FIELDS}
    result.update(productionReady=True, recordType='supported-coverage', limitations=LIMITATIONS)
    # Evidence manifests and development-only limitations are deliberately omitted.
    def audit(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if any(token in key.lower() for token in ['private', 'device', 'email', 'thread', 'attachment']):
                    raise ValueError('Private field in release projection')
                audit(child)
        elif isinstance(value, list):
            for child in value: audit(child)
        elif isinstance(value, str):
            if any(token in value for token in ['/Users/', 'work/', 'file://', 'plugin://']):
                raise ValueError('Local path in release projection')
            if value.startswith(('http:', 'https:')):
                uri = urlsplit(value)
                if uri.scheme != 'https' or uri.netloc not in {'ctlottery.com', 'www.ctlottery.org'}:
                    raise ValueError('Unexpected release source host')
    audit(result)
    return (json.dumps(result, indent=2, ensure_ascii=False, allow_nan=False)+'\n').encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--reviewed-sha256', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    raw = package(args.candidate.read_bytes(), args.reviewed_sha256)
    with args.output.open('xb') as stream: stream.write(raw)
    print(f'Prepared {len(raw)} bytes; SHA256 {hashlib.sha256(raw).hexdigest()}; not published')


if __name__ == '__main__': main()
