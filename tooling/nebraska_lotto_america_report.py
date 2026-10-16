"""Nebraska Lotto America base and All Star Factor literal reports."""
from datetime import datetime
import json
from pathlib import Path
import re
from lxml import html
from tooling.nebraska_draw_results import parse_results, plain

SPECS=json.loads(Path(__file__).with_name('nebraska_lotto_america_specs.json').read_text())


def parse_lotto_america(raw, *, today):
    results=parse_results(raw,'Lotto America',today=today)
    multiplier=results[0]['fields'][2]['values'][0]
    tree=html.fromstring(raw)
    headings=tree.xpath('//h2[contains(.,"drawing results for")]')
    tables=tree.xpath('//table')
    if len(headings)!=2 or len(tables)!=3:
        raise ValueError('Changed Lotto America report structure')
    text=plain(tree)
    qualifications=['The All Star Bonus multiplier does not apply to the jackpot prize.',
                    'Players may add the $1 All Star Bonus',
                    'present cash value is less than the advertised jackpot']
    if any(q not in text for q in qualifications):
        raise ValueError('Missing Lotto America qualification')
    reports=[]
    for i,(title,caption,columns) in enumerate([
        ('Lotto America','Lotto America Regular',['Get','Prize','Odds','Winners']),
        ('Lotto America All Star Factor','Lotto America All Star Factor',['Get','Prize','Winners'])]):
        match=re.fullmatch(re.escape(title)+r' drawing results for (\d{2}/\d{2}/\d{4}), in Nebraska',plain(headings[i]))
        if not match:raise ValueError('Changed report identity/geography')
        stamp=datetime.strptime(match[1],'%m/%d/%Y').date().isoformat()
        if stamp!=results[0]['drawDate']:raise ValueError('Report/result date mismatch')
        table=headings[i].getnext()
        while table is not None and not isinstance(table.tag,str):table=table.getnext()
        if table is not tables[i+1]:raise ValueError('Report/table association mismatch')
        captions=table.xpath('./caption')
        if len(captions)!=1 or plain(captions[0])!=caption:raise ValueError('Changed report variant')
        rows=[[plain(c) for c in r.xpath('./th|./td')] for r in table.xpath('.//tr')]
        expected=SPECS if i==0 else [[r[0],f'{r[1]} X {multiplier}'] for r in SPECS[1:]]
        if len(rows)!=len(expected)+1 or rows[0]!=columns:raise ValueError('Changed report columns/tiers')
        tiers=[]
        for row,spec in zip(rows[1:],expected):
            if len(row)!=len(columns) or row[:-1]!=spec:raise ValueError('Changed prize, multiplier, tier or odds')
            if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)',row[-1]):raise ValueError('Invalid source winner count')
            tier=dict(match=row[0],prizeLabel=row[1],sourceWinners=int(row[-1].replace(',','')))
            if i==0:tier['oddsLabel']=row[2]
            tiers.append(tier)
        reports.append(dict(variant='regular' if i==0 else 'all-star-factor',sourceLabel=caption,drawDate=stamp,tiers=tiers))
    return dict(family='Lotto America',group='lotto-america',sourceUrl=results[0]['sourceUrl'],
                dateZone='America/Chicago',geographicUnit='Nebraska',countUnit='Winners (source label)',
                multiplier=multiplier,reports=reports,qualifications=qualifications,
                limitation='The option is described as All Star Bonus and reported as All Star Factor. Literal multiplier expressions are preserved. Winner categories are not unique people or complete claims; do not sum base and option tables.')
