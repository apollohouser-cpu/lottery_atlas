"""Nebraska Powerball base, Powerplay and Double Play literal reports."""
from datetime import datetime
import json
from pathlib import Path
import re
from lxml import html
from tooling.nebraska_draw_results import parse_results, plain

SPECS=json.loads(Path(__file__).with_name('nebraska_powerball_specs.json').read_text())


def parse_powerball(raw, *, today):
    results=parse_results(raw,'Powerball',today=today)
    multiplier=results[0]['fields'][2]['values'][0]
    tree=html.fromstring(raw)
    headings=tree.xpath('//h2[contains(.,"drawing results for")]')
    tables=tree.xpath('//table')
    if len(headings)!=3 or len(tables)!=5:
        raise ValueError('Changed Powerball report structure')
    text=plain(tree)
    qualifications=['The Match 5 prize is $2 million if the Power Play option is purchased.',
                    'the Power Play multiplier will not apply to Double Play prizes.',
                    'present cash value is less than the advertised jackpot']
    if any(q not in text for q in qualifications):
        raise ValueError('Missing Powerball qualification')
    reports=[]
    for i,(title,caption) in enumerate([
        ('Powerball','Powerball Regular'),
        ('Powerball Powerplay',''),
        ('Powerball Double Play','Powerball Double Play')]):
        columns=['Get','Prize','Odds','Winners']
        match=re.fullmatch(re.escape(title)+r' drawing results for (\d{2}/\d{2}/\d{4}), in Nebraska',plain(headings[i]))
        if not match:raise ValueError('Changed report identity/geography')
        stamp=datetime.strptime(match[1],'%m/%d/%Y').date().isoformat()
        if stamp!=results[2 if i==2 else 0]['drawDate']:raise ValueError('Report/result date mismatch')
        table=headings[i].getnext()
        while table is not None and not isinstance(table.tag,str):table=table.getnext()
        if table is not tables[i+2]:raise ValueError('Report/table association mismatch')
        captions=table.xpath('./caption')
        if len(captions) != (1 if caption else 0) or (caption and plain(captions[0])!=caption):raise ValueError('Changed report variant')
        rows=[[plain(c) for c in r.xpath('./th|./td')] for r in table.xpath('.//tr')]
        expected=SPECS[i]
        if len(rows)!=len(expected)+1 or rows[0]!=columns:raise ValueError('Changed report columns/tiers')
        tiers=[]
        for row,spec in zip(rows[1:],expected):
            if len(row)!=len(columns) or row[:-1]!=spec:raise ValueError('Changed prize, multiplier, tier or odds')
            if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)',row[-1]):raise ValueError('Invalid source winner count')
            tier=dict(match=row[0],prizeLabel=row[1],sourceWinners=int(row[-1].replace(',','')))
            tier['oddsLabel']=row[2]
            tiers.append(tier)
        reports.append(dict(variant=['regular','powerplay','double-play'][i],sourceLabel=title,drawDate=stamp,tiers=tiers))
    return dict(family='Powerball',group='powerball',sourceUrl=results[0]['sourceUrl'],
                dateZone='America/Chicago',geographicUnit='Nebraska',countUnit='Winners (source label)',
                multiplier=multiplier,reports=reports,qualifications=qualifications,
                limitation='Powerplay rows preserve the source Prize labels, which mostly show unmultiplied amounts despite the separate multiplier. Do not present them as computed enhanced payouts. Base and Powerplay source counts may repeat; never sum or infer distinct option purchases. Double Play is a separate drawing and does not use the base jackpot advertisement or Power Play multiplier. Source Winners are not unique people or complete claims.')
