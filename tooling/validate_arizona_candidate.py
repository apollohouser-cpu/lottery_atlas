"""Reject any bytes other than the explicitly reviewed Arizona candidate.

This validates transport/staging identity only. Source refreshes must pass the
private compiler and receive explicit digest review before changing this pin.
"""
import hashlib
from pathlib import Path
import sys

REVIEWED_SHA256 = '23b668a9a2f5c51f8eddf2b66ea7b366d0f3d4c3879111e46bf9c1bb530c670d'


def validate_bytes(payload):
    if hashlib.sha256(payload).hexdigest() != REVIEWED_SHA256:
        raise ValueError('Unreviewed Arizona candidate bytes')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('usage: python3 -m tooling.validate_arizona_candidate FILE')
    payload = Path(sys.argv[1]).read_bytes()
    validate_bytes(payload)
    print(f'Reviewed development candidate: {len(payload)} bytes; productionReady=false')
