"""Validate retained catalog/image continuity; never imply semantic acceptance."""
import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
from tooling.import_delaware_scratch_catalog import parse_catalog


def validate(catalog_path, image_root):
    raw = catalog_path.read_bytes()
    catalog = parse_catalog(raw)
    manifest = json.loads((image_root / 'manifest.json').read_text())
    if manifest.get('complete') is not True or manifest.get('catalogSha256') != hashlib.sha256(raw).hexdigest():
        raise ValueError('Incomplete capture or changed catalog')
    seen = set()
    result = []
    for entry in manifest['entries']:
        gid = entry['gameId']
        if gid in seen or gid not in catalog:
            raise ValueError('Duplicate or unknown image identity')
        seen.add(gid)
        game = catalog[gid]
        if entry.get('status') != 200 or 'error' in entry or entry['url'] != game['detailImage'] or entry['names'] != game['names']:
            raise ValueError('Image source/identity continuity failed')
        mime = entry['contentType']
        suffix = {'image/jpeg': '.jpg', 'image/png': '.png'}.get(mime)
        if suffix is None or entry['file'] != gid + suffix:
            raise ValueError('Invalid image filename/type')
        stamp = datetime.fromisoformat(entry['retrievedAt'])
        if stamp.tzinfo is None:
            raise ValueError('Image acquisition timezone missing')
        data = (image_root / entry['file']).read_bytes()
        signature = b'\xff\xd8\xff' if suffix == '.jpg' else b'\x89PNG\r\n\x1a\n'
        if not data.startswith(signature) or len(data) != entry['bytes'] or hashlib.sha256(data).hexdigest() != entry['sha256']:
            raise ValueError('Image bytes changed')
        result.append({'gameId': gid, 'names': game['names'], 'sourceUrl': entry['url'],
                       'retrievedAt': entry['retrievedAt'], 'sha256': entry['sha256']})
    if seen != set(catalog):
        raise ValueError('Catalog image coverage incomplete')
    return result


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--catalog', type=Path, required=True)
    p.add_argument('--images', type=Path, required=True)
    a = p.parse_args()
    print(f'Validated {len(validate(a.catalog, a.images))} catalog-linked images; semantic review remains separate.')
