"""Refresh the coupled Idaho feed; preserve prior bytes on any failure."""
import argparse
from tooling.idaho_publication import refresh
from tooling.import_idaho_scratch_catalog import fetch

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    data=refresh(args.output,fetch)
    print(f"Validated coupled Idaho coverage: {len(data['results'])} results, {data['scratch']['listedGameCount']} listed Scratch games")
