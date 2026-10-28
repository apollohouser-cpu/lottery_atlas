"""Literal CMS catalog structures, explicitly not inventory or printed game IDs."""
from html.parser import HTMLParser
import re
from urllib.parse import urlsplit,parse_qs

SLUGS={'scratch':'scratch-games','treasure-play':'treasure-play'}
KEYS={'scratch':'e-page-eeedf9c','treasure-play':'e-page-ae879f3'}
VOID={'br','img','input','hr','meta','link','source','wbr','col'}
class Catalog(HTMLParser):
 def __init__(self,kind):
  super().__init__(convert_charrefs=True);self.kind=kind;self.games=[];self.links=[];self.depth=0;self.skip=None;self.capture=None;self.text=[];self.row=None;self.table=None;self.game=None
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='a' and 'href' in a:self.links.append(a['href'])
  if not self.depth:
   if a.get('data-elementor-type')!='loop-item':return
   classes=a.get('class','').split();ids=[v[12:] for v in classes if v.startswith('e-loop-item-')]
   prefix='scratch_amounts-' if self.kind=='scratch' else 'tp_game_type-'
   prices=[v[len(prefix):-6] for v in classes if v.startswith(prefix) and v.endswith('-games')]
   expected='scratch_game' if self.kind=='scratch' else 'treasure_play_game'
   if tag!='div' or len(ids)!=1 or not ids[0].isdigit() or len(prices)!=1 or not prices[0].isdigit() or expected not in classes:raise ValueError('Invalid CMS identity/price/type')
   self.game={'cmsEntryId':ids[0],'identityKind':'website-cms-entry','price':int(prices[0]),'headings':[],'prose':[],'literalText':[],'tables':[],'images':[],'remainingStatus':'unavailable','salesStatus':'unavailable'};self.depth=1;return
  if tag=='div':self.depth+=1
  if tag in ('style','script'):self.skip=tag;return
  if self.skip:return
  if tag=='img':
   src=a.get('src','')
   if not src.startswith('https://montanalottery.com/wp-content/uploads/'):raise ValueError('Unexpected image source')
   self.game['images'].append(src)
  if tag=='table':
   if self.table is not None:raise ValueError('Nested table')
   self.table=[]
  elif tag=='tr' and self.table is not None:
   if self.row is not None:raise ValueError('Unclosed row')
   self.row=[]
  elif tag in ('td','th') and self.table is not None:
   if self.row is None or self.capture is not None or any(a.get(k,'1')!='1' for k in ('rowspan','colspan')):raise ValueError('Invalid table cell')
   self.capture=tag;self.text=[]
  elif tag in ('h2','p') and self.table is None:
   if self.capture is not None:raise ValueError('Nested text block')
   self.capture=tag;self.text=[]
 def handle_data(self,data):
  if self.game is not None and not self.skip and data.strip():self.game['literalText'].append(' '.join(data.split()))
  if self.capture is not None and not self.skip:self.text.append(data)
 def handle_endtag(self,tag):
  if not self.depth:return
  if self.skip:
   if tag==self.skip:self.skip=None
   return
  if tag==self.capture:
   text=' '.join(''.join(self.text).split());self.capture=None
   if tag in ('td','th'):self.row.append(text)
   else:self.game['headings' if tag=='h2' else 'prose'].append(text)
  elif tag=='tr' and self.table is not None:
   if self.row is None or self.capture is not None:raise ValueError('Invalid row')
   self.table.append(self.row);self.row=None
  elif tag=='table':
   if self.table is None or self.row is not None:raise ValueError('Invalid table')
   self.game['tables'].append(self.table);self.table=None
  if tag=='div':
   self.depth-=1
   if self.depth==0:
    if self.capture or self.table is not None:raise ValueError('Unclosed catalog entry')
    self.games.append(self.game);self.game=None

def parse_page(html,kind):
 if kind not in SLUGS:raise ValueError('Unsupported product')
 p=Catalog(kind);p.feed(html);p.close()
 if p.depth or not p.games:raise ValueError('Missing/unclosed entries')
 ids=set()
 for g in p.games:
  if g['cmsEntryId'] in ids:raise ValueError('Duplicate entry')
  ids.add(g['cmsEntryId'])
  g['literalText']=' '.join(g['literalText'])
  headings=g.pop('headings')
  if len(headings) not in (1,2) or not headings[-1].startswith('Overall Odds '):raise ValueError('Invalid title/odds')
  g['title']=headings[0] if len(headings)==2 else None
  g['titleStatus']='published' if g['title'] else 'unavailable'
  g['overallOddsText']=headings[-1]
  if len(g['tables'])!=1 or len(g['tables'][0])<2 or g['tables'][0][0]!=['WIN','PRIZE','ODDS']:raise ValueError('Invalid schedule')
  for row in g['tables'][0][1:]:
   if len(row)!=3 or any(not v for v in row):raise ValueError('Invalid literal row')
  # Prize text remains categorical/literal: vehicles, Ticket, Jackpot and combinations.
  g['scheduleRows']=[dict(zip(['winText','prizeText','oddsText'],r)) for r in g.pop('tables')[0][1:]]
 pages={1}
 root='https://montanalottery.com/'+SLUGS[kind]+'/'
 for link in p.links:
  if link.startswith(root+'?'+KEYS[kind]+'='):
   q=parse_qs(urlsplit(link).query)
   if set(q)!={KEYS[kind]} or len(q[KEYS[kind]])!=1 or not q[KEYS[kind]][0].isdigit():raise ValueError('Invalid pagination')
   n=int(q[KEYS[kind]][0])
   if not 1<=n<=100:raise ValueError('Invalid page number')
   pages.add(n)
 return {'kind':kind,'entries':p.games,'linkedPages':sorted(pages)}

def combine_pages(pages,kind):
 if not pages or set(pages)!=set(range(1,max(pages)+1)):raise ValueError('Missing catalog page')
 parsed={n:parse_page(s,kind) for n,s in pages.items()}
 if any(not set(p['linkedPages'])<=set(pages) for p in parsed.values()):raise ValueError('Unretrieved pagination')
 entries=[g for n in sorted(parsed) for g in parsed[n]['entries']]
 if len({g['cmsEntryId'] for g in entries})!=len(entries):raise ValueError('Duplicate cross-page identity')
 return {'kind':kind,'coverage':'Published catalog and literal prize structures; not active-sales proof, inventory or claims.','entries':entries}
