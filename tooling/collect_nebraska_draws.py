"""Private staging collector; not wired to public refresh until schedule gates close."""
from datetime import datetime
import json
import os
from pathlib import Path
import tempfile
from urllib.parse import quote_plus
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

from tooling.nebraska_draw_collection import assemble_collection
from tooling.nebraska_draw_results import SPECS


def fetch_page(url):
    request = Request(url, headers={'User-Agent': 'LotteryAtlas source validation'})
    with urlopen(request, timeout=45) as response:
        if response.status != 200:
            raise ValueError('Unexpected source status')
        raw = response.read(5_000_001)
        if len(raw) > 5_000_000:
            raise ValueError('Oversized source response')
        return raw


def collect(output, *, fetch=fetch_page, now=None, publish=False):
    """Validate all families before replacing staging bytes, preserving failures."""
    now = now or datetime.now(ZoneInfo('America/Chicago'))
    if now.tzinfo is None or now.utcoffset() is None:
        raise ValueError('Retrieval time must be timezone-aware')
    output = Path(output)
    previous = json.loads(output.read_text()) if output.exists() else None
    pages = {}
    for family in SPECS:
        url = 'https://nelottery.com/lotto-detail?gamename=' + quote_plus(family)
        pages[family] = fetch(url)
    result = assemble_collection(pages, today=now.astimezone(ZoneInfo('America/Chicago')).date(), previous=previous)
    result['retrievedAt'] = now.isoformat()
    if publish:
        result['schemaVersion'] = 1
    else:
        result['stage'] = 'private-validation-only'
    payload = json.dumps(result, indent=2, ensure_ascii=False) + '\n'
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=output.parent,
                                         prefix='.' + output.name + '.', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return result


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--publish', action='store_true')
    args = parser.parse_args()
    result = collect(args.output, publish=args.publish)
    print(f"Validated {len(result['results'])} results / {len(result['familyReports'])} family reports")
