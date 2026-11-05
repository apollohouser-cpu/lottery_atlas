"""Repeatable, atomic development-candidate packaging from private captures.

No network collection, public upload, production marker or automatic digest
approval. Both snapshots are revalidated; their cached `validated` sections are
never trusted. The printed digest is for explicit review by the app maintainer.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile

from arizona_coverage import compile_coverage


def read_captures(path):
    envelope = json.loads(Path(path).read_text(encoding='utf-8'))
    if (not isinstance(envelope, dict)
            or envelope.get('schemaVersion') != 1
            or envelope.get('status') != 'private-development-snapshot'
            or envelope.get('productionReady') is not False
            or not isinstance(envelope.get('captures'), dict)):
        raise ValueError('Expected a private development source snapshot')
    return envelope['captures']


def package(candidate, retained, destination, *, check=False):
    # Finish all source validation before touching an existing artifact.
    coverage = compile_coverage(read_captures(candidate), read_captures(retained))
    payload = (json.dumps(coverage, ensure_ascii=False, sort_keys=True,
                          indent=2) + '\n').encode('utf-8')
    destination = Path(destination)
    if destination.resolve() in {Path(candidate).resolve(), Path(retained).resolve()}:
        raise ValueError('Destination must not overwrite private source captures')
    if check:
        if destination.read_bytes() != payload:
            raise ValueError('Candidate differs from revalidated source captures')
    else:
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=destination.parent,
                    prefix='.' + destination.name + '.', delete=False) as stream:
                temporary = Path(stream.name)
                stream.write(payload)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, destination)
            temporary = None
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    return {'sha256': hashlib.sha256(payload).hexdigest(), 'bytes': len(payload),
            'productionReady': False, 'checkedOnly': check}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--retained', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--check', action='store_true', help='Verify existing bytes without writing')
    args = parser.parse_args()
    print(json.dumps(package(args.candidate, args.retained, args.output,
                             check=args.check), sort_keys=True))


if __name__ == '__main__':
    main()
