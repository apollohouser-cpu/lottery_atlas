"""Collect only reviewed official ND catalog, result and rule URLs."""
import argparse
import json
from urllib.request import Request, HTTPRedirectHandler, build_opener
from tooling.north_dakota_coverage import refresh, CATALOG_URL, GAMES, draws, SPEC_PATH


def official_fetch(url):
    specs = json.loads(SPEC_PATH.read_text())
    allowed = {CATALOG_URL} | {draws.source_url(g) for g in GAMES} | {specs[g]['sourceUrl'] for g in GAMES}
    if url not in allowed:
        raise ValueError('Unreviewed North Dakota source URL')
    class NoRedirect(HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, hdrs, newurl):
            raise ValueError('Source redirect requires review')
    with build_opener(NoRedirect).open(Request(url, headers={'User-Agent':'LotteryAtlas/1.0'}), timeout=45) as response:
        if response.status != 200:
            raise ValueError('Unexpected source status')
        return response.read()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    data = refresh(args.output, official_fetch)
    print(f"Validated North Dakota: {len(data['results'])} results; {len(data['rules'])} rules; {len(data['sources'])} sources; collected {data['updatedAt']}")
