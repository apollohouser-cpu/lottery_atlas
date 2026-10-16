"""Literal 2by2 source reports with explicit Tuesday eligibility."""
from datetime import datetime
from pathlib import Path
import json
import re
from lxml import html
from tooling.nebraska_draw_results import parse_results, plain

SPECS = json.loads(Path(__file__).with_name('nebraska_2by2_specs.json').read_text())


def parse_2by2(raw, *, today):
    results = parse_results(raw, '2by2', today=today)
    tree = html.fromstring(raw)
    tables = tree.xpath('//table')
    if len(tables) != 4:
        raise ValueError('Changed 2by2 table count')
    def rows(table):
        return [[plain(c) for c in r.xpath('./th|./td')] for r in table.xpath('.//tr')]
    if rows(tables[0]) != SPECS['schedule']:
        raise ValueError('Changed 2by2 schedule')
    text = plain(tree)
    required = ['Any Multi-draw selection that is not divisible by 7 is not eligible',
                'all prizes won on Tuesday automatically double in value',
                'then prizes will be awarded on a pari-mutuel basis']
    if any(x not in text for x in required):
        raise ValueError('Missing eligibility or liability qualification')
    headings = tree.xpath('//h2[contains(.,"drawing results for")]')
    if len(headings) != 2:
        raise ValueError('Missing or ambiguous 2by2 report')
    reports = []
    for i, (variant, title, columns) in enumerate([
            ('regular', '2by2', ['Get','Prize','Odds','Winners']),
            ('tuesday', '2by2 Tuesday', ['Get','Prize','Winners'])]):
        match = re.fullmatch(re.escape(title)+r' drawing results for (\d{2}/\d{2}/\d{4}), in Nebraska',plain(headings[i]))
        if not match:
            raise ValueError('Changed report heading or geography')
        day = datetime.strptime(match[1], '%m/%d/%Y').date()
        if day.isoformat() != results[0]['drawDate']:
            raise ValueError('Report/result date mismatch')
        table = headings[i].getnext()
        while table is not None and not isinstance(table.tag,str):
            table = table.getnext()
        if table is not tables[i+2]:
            raise ValueError('Report/table association mismatch')
        captions = table.xpath('./caption')
        if len(captions)!=1 or plain(captions[0]) != ('2by2 Regular' if i==0 else title):
            raise ValueError('Changed variant caption')
        cells = rows(table)
        if len(cells)!=5 or cells[0]!=columns:
            raise ValueError('Changed report columns/tiers')
        applicable = variant=='regular' or day.weekday()==1
        tiers=[]
        for row,spec in zip(cells[1:],SPECS[variant]):
            if len(row)!=len(columns) or row[:-1]!=spec:
                raise ValueError('Changed literal prize or tier')
            if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)',row[-1]):
                raise ValueError('Invalid source winner count')
            winners=int(row[-1].replace(',',''))
            if not applicable and winners!=0:
                raise ValueError('Nonzero Tuesday winners on non-Tuesday')
            tier={'match':row[0],'prizeLabel':row[1]}
            if variant=='regular':tier['oddsLabel']=row[2]
            if applicable:tier['sourceWinners']=winners
            tiers.append(tier)
        reports.append(dict(variant=variant,drawDate=day.isoformat(),applicable=applicable,tiers=tiers,
                            countUnit='Winners (source label)' if applicable else None))
    return dict(family='2by2',sourceUrl=results[0]['sourceUrl'],dateZone='America/Chicago',
                geographicUnit='Nebraska',reports=reports,
                schedule=[dict(zip(SPECS['schedule'][0],r)) for r in SPECS['schedule'][1:]],
                qualifications=required,
                limitation='Tuesday prizes require eligible multi-draw purchases and a Tuesday draw. Off-Tuesday source zero placeholders are omitted from winner counts. Source Winners are not unique people or complete claims. Do not sum overlapping categories.')
