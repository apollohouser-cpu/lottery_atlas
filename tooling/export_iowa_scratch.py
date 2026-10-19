"""Export the verified Scratch projection from the coupled Iowa snapshot."""
import json
from pathlib import Path
import os
import tempfile


def export(source, output):
    coverage = json.loads(Path(source).read_text())
    if coverage.get('schemaVersion') != 1 or coverage.get('state') != 'Iowa':
        raise ValueError('Unsupported Iowa snapshot')
    catalog = coverage['scratchCatalog']
    typed = next(s for s in coverage['instantInventories']['inventories'] if s['productType'] == 'Scratch')
    keys = ('id', 'name', 'cost', 'prizeTiers')
    if catalog['sourceDate'] != coverage['instantInventories']['sourceDate'] or [
        {k:g[k] for k in keys} for g in catalog['games']
    ] != [{k:g[k] for k in keys} for g in typed['games']]:
        raise ValueError('Scratch projection differs from coupled inventory')
    result = dict(source='Iowa Lottery dated Scratch prize inventory', updatedAt=coverage['retrievedAt'], catalogs=[catalog])
    output = Path(output)
    if output.exists():
        old = json.loads(output.read_text())
        if old.get('catalogs') == result['catalogs']:
            result['updatedAt'] = old['updatedAt']
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=output.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(json.dumps(result, indent=2)+'\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
    finally:
        if temporary:
            temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source')
    parser.add_argument('output')
    args = parser.parse_args()
    export(args.source, args.output)
