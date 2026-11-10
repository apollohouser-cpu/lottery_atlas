"""Reject any bytes other than the explicitly reviewed Delaware candidate.

This validates transport/staging identity only. Source refreshes must pass the
private compiler and receive explicit digest review before changing this pin.
"""
import hashlib
from pathlib import Path
import sys

REVIEWED_SHA256 = '9a9a37116452b8f7cb4239b10475a196b31a723e5231cec8be27a61925f76c08'


def validate_bytes(payload):
    if hashlib.sha256(payload).hexdigest() != REVIEWED_SHA256:
        raise ValueError('Unreviewed Delaware candidate bytes')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('usage: python3 -m tooling.validate_delaware_candidate FILE')
    payload = Path(sys.argv[1]).read_bytes()
    validate_bytes(payload)
    print(f'Reviewed development candidate: {len(payload)} bytes; productionReady=false')
