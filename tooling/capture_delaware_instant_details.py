"""Capture only catalog-linked official images into a new private evidence directory."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
from urllib.parse import quote, urlsplit
from urllib.request import Request, urlopen
from tooling.import_delaware_scratch_catalog import parse_catalog


def capture(catalog_path, output):
    raw = catalog_path.read_bytes()
    catalog = parse_catalog(raw)
    output.mkdir(parents=True, exist_ok=False)
    manifest = {'catalogSha256': hashlib.sha256(raw).hexdigest(),
                'startedAt': datetime.now(timezone.utc).isoformat(), 'entries': [], 'complete': False}
    manifest_path = output / 'manifest.json'
    for game_id, game in sorted(catalog.items()):
        url = game['detailImage']
        entry = {'gameId': game_id, 'names': game['names'], 'url': url}
        try:
            with urlopen(Request(quote(url, safe=":/?=&%"), headers={'User-Agent': 'LotteryAtlas source audit'}), timeout=40) as response:
                final = urlsplit(response.geturl())
                if final.scheme != 'https' or final.hostname != 'delotterywebcontent.blob.core.windows.net':
                    raise ValueError('Unexpected redirected image host')
                data = response.read()
                mime = response.headers.get('Content-Type', '').split(';')[0]
                if response.status != 200 or mime not in ('image/jpeg', 'image/png'):
                    raise ValueError('Unexpected image response')
                if not (data.startswith(b'\xff\xd8\xff') or data.startswith(b'\x89PNG\r\n\x1a\n')):
                    raise ValueError('Image signature missing')
                filename = game_id + ('.jpg' if mime == 'image/jpeg' else '.png')
                (output / filename).write_bytes(data)
                entry.update(file=filename, bytes=len(data), sha256=hashlib.sha256(data).hexdigest(),
                             contentType=mime, retrievedAt=datetime.now(timezone.utc).isoformat(), status=200)
        except Exception as error:
            entry['error'] = str(error)
        manifest['entries'].append(entry)
        manifest_path.write_text(json.dumps(manifest, indent=2)+'\n')
    manifest['complete'] = all('error' not in e for e in manifest['entries'])
    manifest['finishedAt'] = datetime.now(timezone.utc).isoformat()
    manifest_path.write_text(json.dumps(manifest, indent=2)+'\n')
    if not manifest['complete']:
        raise ValueError('Incomplete capture; inspect private manifest. No public data changed.')
    return len(manifest['entries'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--catalog', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    print(f'Captured {capture(args.catalog, args.output)} official images; contents still require audit.')
