"""Gate literal catalog contracts; only labeled progressive estimates may change."""
import copy,json,re
from pathlib import Path

SPEC_PATH=Path(__file__).with_name('montana_catalog_specs.json')
ESTIMATE=re.compile(r'Current Jackpot: (\$(?:0|[1-9]\d{0,2}(?:,\d{3})*))(?![\d,.])')

def typed_catalog(catalog):
 result=copy.deepcopy(catalog)
 for g in result['entries']:
  text=g['literalText'];matches=list(ESTIMATE.finditer(text))
  if text.count('Current Jackpot:')!=len(matches) or len(matches)>1:raise ValueError('Malformed progressive estimate')
  if matches and result['kind']!='treasure-play':raise ValueError('Unexpected Scratch estimate')
  amount=matches[0].group(1) if matches else None
  g['advertisedJackpot']={'status':'published' if amount else 'unavailable','amountText':amount,'meaning':'Advertised progressive estimate only; not an actual payout, stock or winner count.'}
  if amount:
   # Replace only this labeled amount, never schedule prizes or starting jackpot.
   g['literalText']=ESTIMATE.sub('Current Jackpot: [advertised estimate]',text)
   g['prose']=[ESTIMATE.sub('Current Jackpot: [advertised estimate]',v) for v in g['prose']]
 return result

def stable(catalog):
 result=copy.deepcopy(catalog)
 for g in result['entries']:g['advertisedJackpot']['amountText']=None
 result['entries'].sort(key=lambda g:g['cmsEntryId'])
 return result

def validate_catalog(catalog):
 actual=typed_catalog(catalog)
 specs=json.loads(SPEC_PATH.read_text())
 if actual['kind'] not in specs or stable(actual)!=specs[actual['kind']]:raise ValueError('Changed catalog identity/schedule/status requires review')
 return actual

def continuity(prior,candidate):
 if stable(prior)!=stable(candidate):raise ValueError('Catalog contract changed')
 return candidate
