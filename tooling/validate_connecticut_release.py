"""Validate exact reviewed Connecticut release bytes before publication."""
import hashlib
from pathlib import Path
import sys

REVIEWED_SHA256 = '10ca4859d574887366c2fd027266dfabd50ec916e1c3d804ab7ff8a084c538dd'


def validate(path):
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != REVIEWED_SHA256:
        raise ValueError('Unreviewed Connecticut release; preserve previous public bytes')
    return raw


if __name__ == '__main__':
    validate(Path(sys.argv[1]))
    print('Exact reviewed Connecticut release verified')
