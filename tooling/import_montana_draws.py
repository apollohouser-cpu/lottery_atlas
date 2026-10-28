"""Strict Montana history tables; never substitute newer headline results/counts."""
from datetime import date, datetime, timezone
from html.parser import HTMLParser
from zoneinfo import ZoneInfo
import re

# Reviewed capture window floor, not a game inception date.
SUPPORTED_FROM = date(2026, 4, 26)
SPECS = {
    'powerball': ('Powerball', ['Date','Numbers','PB','PP','Jackpot'],5,69,26,{0,2,5}),
    'powerball-double-play': ('Powerball', ['Date','Numbers','PB','Jackpot'],5,69,26,{0,2,5}),
    'mega-millions': ('Mega Millions', ['Date','Numbers','Mega Ball','Jackpot'],5,70,24,{1,4}),
    'millionaire-for-life': ('Millionaire For Life', ['Date','Numbers','1/5'],5,58,5,set(range(7))),
    'lotto-america': ('Lotto America', ['Date','Numbers','SB','ASB','Jackpot'],5,52,10,{0,2,5}),
    'montana-cash': ('Montana Cash', ['Date','Numbers','MT Cash','Max Cash','Combined Jackpot'],5,45,0,{2,5}),
    'big-sky-bonus': ('Big Sky Bonus', ['Date','Numbers','BN','Jackpot'],4,31,16,set(range(7))),
}

def source_url(game):
    return 'https://montanalottery.com/'+('powerball' if game=='powerball-double-play' else game)+'/'

class Tables(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables=[]; self.titles=[]
        self.table=self.row=self.cell=self.title=None
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if tag=='title':
            if self.title is not None: raise ValueError('Nested title')
            self.title=[]
        if tag=='table':
            if self.table is not None: raise ValueError('Nested result table')
            if 'winning-numbers-table' in a.get('class','').split(): self.table=[]
        elif self.table is not None:
            if tag=='tr':
                if self.row is not None: raise ValueError('Unclosed row')
                self.row=[]
            elif tag in ('td','th'):
                if self.row is None or self.cell is not None or any(a.get(k,'1')!='1' for k in ('rowspan','colspan')): raise ValueError('Invalid cell')
                self.cell=[]
    def handle_data(self, data):
        if self.title is not None: self.title.append(data)
        if self.cell is not None: self.cell.append(data)
    def handle_endtag(self, tag):
        if tag=='title' and self.title is not None:
            self.titles.append(''.join(self.title)); self.title=None
        if self.table is None: return
        if tag in ('td','th'):
            if self.cell is None: raise ValueError('Unexpected cell close')
            self.row.append(' '.join(''.join(self.cell).split())); self.cell=None
        elif tag=='tr':
            if self.row is None or self.cell is not None: raise ValueError('Invalid row close')
            self.table.append(self.row); self.row=None
        elif tag=='table':
            if self.row is not None: raise ValueError('Unclosed row')
            self.tables.append(self.table); self.table=None

def numbers(text,count,maximum):
    if not re.fullmatch(r'[1-9]\d*(?:, [1-9]\d*)*',text): raise ValueError('Invalid numbers')
    values=[int(v) for v in text.split(', ')]
    if len(values)!=count or len(set(values))!=count or any(v>maximum for v in values): raise ValueError('Invalid number range/cardinality')
    return values

def money(text):
    if not re.fullmatch(r'\$(?:0|[1-9]\d{0,2}(?:,\d{3})*)',text): raise ValueError('Invalid advertised amount')
    return int(text[1:].replace(',',''))

def parse_draws(html,game,*,retrieved_at):
    if game not in SPECS or not isinstance(html,str): raise ValueError('Unsupported game/input')
    captured=datetime.fromisoformat(retrieved_at.replace('Z','+00:00'))
    if captured.tzinfo is None or captured.utcoffset().total_seconds()!=0: raise ValueError('Capture must be UTC')
    title,headers,count,maximum,bonus_max,days=SPECS[game]
    p=Tables();p.feed(html);p.close()
    if any(v is not None for v in (p.title,p.table,p.row,p.cell)): raise ValueError('Unclosed markup')
    expected=[SPECS['powerball'][1],SPECS['powerball-double-play'][1]] if title=='Powerball' else [headers]
    if p.titles!=[title+' - Montana Lottery'] or [t[0] if t else [] for t in p.tables]!=expected: raise ValueError('Wrong identity/table inventory')
    table=p.tables[expected.index(headers)]
    if len(table)<3: raise ValueError('Fewer than two dates')
    out=[];previous=None
    for cells in table[1:]:
        if len(cells)!=len(headers) or not re.fullmatch(r'\d{2}\.\d{2}\.\d{4}',cells[0]): raise ValueError('Invalid date/shape')
        m,d,y=map(int,cells[0].split('.'));drawn=date(y,m,d)
        if drawn<SUPPORTED_FROM or drawn>captured.astimezone(ZoneInfo('America/Denver')).date() or drawn.weekday() not in days or (previous is not None and drawn>=previous): raise ValueError('Unsupported date/cadence/order')
        previous=drawn
        primary=numbers(cells[1],count,maximum)
        bonus=numbers(cells[2],1,bonus_max) if bonus_max else []
        multiplier=None
        if game in ('powerball','lotto-america'):
            if cells[3] not in (['2','3','4','5','10'] if game=='powerball' else ['2','3','4','5']): raise ValueError('Invalid multiplier')
            multiplier=int(cells[3])
        if game=='montana-cash':
            amounts=[money(v) for v in cells[2:]]
            if amounts[0]+amounts[1]!=amounts[2]: raise ValueError('Combined advertised amount mismatch')
        elif 'Jackpot' in headers: money(cells[-1])
        out.append(dict(game=game,drawDate=drawn.isoformat(),datePrecision='day',numbers=primary,bonusNumbers=bonus,multiplier=multiplier,sourceUrl=source_url(game),sourceRetrievedAt=captured.astimezone(timezone.utc).isoformat(),reportStatus='unavailable'))
    return out
