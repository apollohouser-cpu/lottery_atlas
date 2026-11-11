"""Prepare an immutable release artifact from explicitly reviewed candidate bytes.

Does not publish, enable app routes, collect new observations, or declare state
acceptance. The production marker describes the artifact format; native/live
release verification remains a separate acceptance requirement.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile

from tooling.validate_delaware_candidate import validate_bytes


def release_bytes(candidate):
    validate_bytes(candidate)
    data = json.loads(candidate.decode('utf-8'))
    if (data.get('stateCode') != 'DE' or data.get('schemaVersion') != 1
            or data.get('recordType') != 'incomplete-development-candidate'
            or data.get('productionReady') is not False):
        raise ValueError('Invalid reviewed candidate identity')
    data['recordType'] = 'supported-coverage'
    data['productionReady'] = True
    return (json.dumps(data, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode('utf-8')


def package(source, destination, *, check=False):
    source, destination = Path(source), Path(destination)
    if source.resolve() == destination.resolve():
        raise ValueError('Release must not overwrite its reviewed candidate')
    payload = release_bytes(source.read_bytes())
    if check:
        if destination.read_bytes() != payload:
            raise ValueError('Release differs from reviewed candidate')
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
                temporary.unlink()
    return {'bytes': len(payload), 'sha256': hashlib.sha256(payload).hexdigest(),
            'checkedOnly': check}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    print(json.dumps(package(args.candidate, args.output, check=args.check), sort_keys=True))
