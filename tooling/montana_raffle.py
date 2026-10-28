"""Reviewed current raffle offer, never historical or planned counts as results."""
import copy,json
from pathlib import Path
from tooling.montana_rules import Sections

IDS=['data-id:ed510c5','data-id:d700e65','eael-data-table-wrapper-d476170','eael-data-table-wrapper-ab48f81','e-n-tab-content-1006112491','e-n-tab-content-1006112493']
SPEC_PATH=Path(__file__).with_name('montana_raffle_spec.json')

def extract_offer(html):
 p=Sections(IDS);p.feed(html);p.close()
 if p.root is not None or p.title is not None or p.titles!=['Montana millionaire - Montana Lottery'] or sorted(s['id'] for s in p.sections)!=sorted(IDS):raise ValueError('Invalid raffle identity/sections')
 return p.sections

def parse_raffle(html):
 spec=json.loads(SPEC_PATH.read_text())
 if extract_offer(html)!=spec['sections']:raise ValueError('Changed raffle offer requires review')
 return copy.deepcopy(spec)
