"""Nebraska current Mega Millions per-play multiplier report and schedules."""
from datetime import date, datetime
from pathlib import Path
import json
import re
from lxml import html
from tooling.nebraska_draw_results import parse_results, plain

SPECS=json.loads(Path(__file__).with_name('nebraska_mega_millions_specs.json').read_text())


def parse_mega_millions(raw, *, today):
    results=parse_results(raw,'Mega Millions',today=today)
    if date.fromisoformat(results[0]['drawDate'])<date(2025,4,8):
        raise ValueError('Old rules unsupported')
    tree=html.fromstring(raw);tables=tree.xpath('//table')
    if len(tables)!=4:raise ValueError('Changed Mega Millions tables')
    def rows(table):return [[plain(c) for c in r.xpath('./th|./td')] for r in table.xpath('.//tr')]
    for table,key in zip(tables[:2],['multiplierSchedule','prizeSchedule']):
        if rows(table)!=SPECS[key]:raise ValueError('Changed current schedule')
    headings=tree.xpath('//h2[contains(.,"drawing results for")]')
    if len(headings)!=1:raise ValueError('Ambiguous report heading')
    m=re.fullmatch(r'Mega Millions drawing results for (\d{2}/\d{2}/\d{4}), in Nebraska',plain(headings[0]))
    if not m or datetime.strptime(m[1],'%m/%d/%Y').date().isoformat()!=results[0]['drawDate']:
        raise ValueError('Report date/geography mismatch')
    table=headings[0].getnext()
    while table is not None and not isinstance(table.tag,str):table=table.getnext()
    if table is not tables[3]:raise ValueError('Report/table association mismatch')
    text=plain(tree)
    qualifications=['Each play costs $5','a multiplier is randomly assigned',
                    'The multiplier does not apply to the jackpot prize.',
                    'present cash value is less than the advertised jackpot']
    if any(q not in text for q in qualifications):raise ValueError('Missing current rules')
    cells=[]
    for row in table.xpath('.//tr'):
        values=[plain(c) for c in row.xpath('./th|./td')]
        if not values:
            if plain(row):raise ValueError('Unrecognized report row')
            continue
        cells.append(values)
    tiers=[];cursor=0
    for index,label in enumerate(SPECS['reportLabels']):
        if cursor>=len(cells) or cells[cursor]!=[label,'Winners']:raise ValueError('Changed report match label')
        cursor+=1;counts=[]
        for multiplier in ([1] if index==0 else [2,3,4,5,10]):
            if cursor>=len(cells):raise ValueError('Missing multiplier row')
            row=cells[cursor];cursor+=1
            if len(row)!=2 or row[0]!=f'{multiplier}X':raise ValueError('Changed multiplier order')
            if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)',row[1]):raise ValueError('Invalid winner count')
            counts.append(dict(multiplier=multiplier,sourceWinners=int(row[1].replace(',',''))))
        tiers.append(dict(sourceMatchLabel=label,counts=counts))
    if cursor!=len(cells):raise ValueError('Unexpected report rows')
    return dict(family='Mega Millions',group='mega-millions',drawDate=results[0]['drawDate'],
                sourceUrl=results[0]['sourceUrl'],dateZone='America/Chicago',geographicUnit='Nebraska',
                countUnit='Winners (source label)',tiers=tiers,qualifications=qualifications,
                prizeSchedule=SPECS['prizeSchedule'],multiplierSchedule=SPECS['multiplierSchedule'],
                limitation='Report headings contain base-prize amounts before the per-play multiplier; current prize ranges are shown separately. Jackpot 1X is the source label for its unmultiplied category, not a purchasable 1X option. No calculated payout or unique-person/complete-claims total is inferred.')
