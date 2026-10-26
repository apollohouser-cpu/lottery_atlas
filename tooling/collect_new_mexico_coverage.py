"""Refresh coupled New Mexico coverage; retain the previous snapshot on failure.

Run from the repository root with python3 -m tooling.collect_new_mexico_coverage.
"""
import argparse
from tooling.new_mexico_coverage import refresh
from tooling.import_new_mexico_scratch_catalog import fetch

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    data=refresh(args.output,fetch)
    print(f"Validated New Mexico coverage: {len(data['results'])} results; "
          f"{sum(r['report'] is not None for r in data['results'])} exact reports; "
          f"{len(data['scratch']['games'])} estimated top-prize Scratch entries")
