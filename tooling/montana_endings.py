"""Reviewed two-page ending notice; changed PDF bytes require a fresh visual audit."""
import copy
import hashlib
import json
from pathlib import Path
from datetime import datetime

SPEC_PATH=Path(__file__).with_name('montana_ending_spec.json')

def parse_endings(raw,*,retrieved_at):
 spec=json.loads(SPEC_PATH.read_text())
 if not isinstance(raw,bytes) or hashlib.sha256(raw).hexdigest()!=spec['sha256']:
  raise ValueError('Changed ending notice requires review')
 captured=datetime.fromisoformat(retrieved_at.replace('Z','+00:00'))
 if captured.tzinfo is None or captured.utcoffset().total_seconds()!=0:raise ValueError('Capture must be UTC')
 return {**copy.deepcopy(spec),'sourceRetrievedAt':captured.isoformat()}
