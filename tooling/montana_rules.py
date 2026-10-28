"""Fail-closed literal Montana rule text/table contracts; no payout inference."""
import copy
import json
from html.parser import HTMLParser
from pathlib import Path
from tooling.import_montana_draws import SPECS

SPEC_PATH=Path(__file__).with_name('montana_rule_specs.json')
PANELS=['e-n-tab-content-100611249'+str(i) for i in (3,4,5)]
VOID={'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}

class Sections(HTMLParser):
    def __init__(self, section_ids=None):
        self.section_ids=section_ids or PANELS+['eael-data-table-wrapper-553a46a']
        super().__init__(convert_charrefs=True)
        self.sections=[];self.stack=[];self.root=None;self.events=[];self.pending='';self.ignore=0
        self.titles=[];self.title=None
    def flush(self):
        if self.pending.strip():self.events.append(['text',' '.join(self.pending.split())])
        self.pending=''
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='title':self.title=[]
        if self.root is None:
            key=a.get('id')
            if key not in self.section_ids:key='data-id:'+a.get('data-id','')
            if key not in self.section_ids:return
            self.root=key;self.stack=[];self.events=[]
        self.flush()
        if tag in ('script','style','svg') or self.ignore:
            if tag not in VOID:self.ignore+=1;self.stack.append(tag)
            return
        if len(attrs)!=len(a):raise ValueError('Duplicate rule attributes')
        kept={k:v for k,v in a.items() if k in ('rowspan','colspan','href','src','alt')}
        self.events.append(['start',tag,kept])
        if tag not in VOID:self.stack.append(tag)
    def handle_startendtag(self,tag,attrs):
        self.handle_starttag(tag,attrs)
        if tag not in VOID:self.handle_endtag(tag)
    def handle_data(self,data):
        if self.title is not None:self.title.append(data)
        if self.root is not None and not self.ignore:self.pending+=data
    def handle_endtag(self,tag):
        if tag=='title' and self.title is not None:
            self.titles.append(''.join(self.title));self.title=None
        if self.root is None or tag in VOID:return
        self.flush()
        if not self.stack or self.stack[-1]!=tag:raise ValueError('Unbalanced Montana rules')
        self.stack.pop()
        if self.ignore:self.ignore-=1
        else:self.events.append(['end',tag])
        if not self.stack:
            self.sections.append({'id':self.root,'events':self.events});self.root=None

def extract_rules(html,game):
    if game not in SPECS or game=='powerball-double-play':raise ValueError('Unsupported rule family')
    p=Sections();p.feed(html);p.close()
    ids=[v['id'] for v in p.sections]
    expected=PANELS+(['eael-data-table-wrapper-553a46a'] if game=='powerball' else [])
    if p.root is not None or p.title is not None or sorted(ids)!=sorted(expected) or p.titles!=[SPECS[game][0]+' - Montana Lottery']:
        raise ValueError('Missing/duplicate rule sections or wrong identity')
    return p.sections

def parse_rules(html,game):
    specs=json.loads(SPEC_PATH.read_text())
    if game not in specs:raise ValueError('Unsupported rule family')
    if extract_rules(html,game)!=specs[game]['sections']:raise ValueError('Changed Montana rules require review')
    return {'game':game,'coverage':'Literal source rules and schedules, not dated payouts; source discrepancies retained.',**copy.deepcopy(specs[game])}
