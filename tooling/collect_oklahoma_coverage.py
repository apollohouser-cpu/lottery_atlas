"""Refresh coupled Oklahoma coverage, retaining the previous snapshot on failure."""
import argparse
from oklahoma_coverage import refresh
from import_oklahoma_scratch_catalog import fetch

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    data = refresh(args.output, fetch)
    print(f"Validated Oklahoma coverage: {len(data['results'])} results; "
          f"{len(data['products']['scratch']['games'])} Scratch; "
          f"{len(data['products']['fastPlay']['games'])} Fast Play")
