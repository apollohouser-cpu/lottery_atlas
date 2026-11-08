"""Current-rule dated Delaware reports; legacy Megaplier table stays excluded."""
from datetime import datetime
import re
from urllib.parse import parse_qs, urlsplit
from lxml import html
from tooling.delaware_multiwin_report import text

SOURCE = 'https://www.delottery.com/Drawing-Games/Mega-Millions/Number-Of-Winners'
BASES = [('5',1000000),('4 + Mega',10000),('4',500),('3 + Mega',200),
         ('3',10),('2 + Mega',10),('1 + Mega',7),('Mega',5)]
MULTIPLIERS = [2,3,4,5,10]


def parse(raw, *, source_url, observed_date):
    if source_url != SOURCE: raise ValueError('Wrong report source')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != ['Number Of Winners - Mega Millions - Drawing Games | Delaware Lottery'] or not tree.xpath('//h2[normalize-space(.)="Number of Delaware Winners"]'):
        raise ValueError('Changed report identity/geography')
    panels = tree.xpath('//div[starts-with(@id,"collapseWinners") and @id!="collapseWinnersnewmm" and @id!="collapseWinnersoldmm"]')
    if not panels: raise ValueError('Missing dated reports')
    reports = []; previous = None
    for panel in panels:
        key = panel.get('id').removeprefix('collapseWinners')
        if not re.fullmatch(r'\d{8}',key): raise ValueError('Invalid report date identity')
        draw = datetime.strptime(key,'%Y%m%d').date()
        if draw > observed_date or (previous is not None and draw >= previous): raise ValueError('Future/duplicate/unordered report')
        previous = draw
        heading = panel.getprevious()
        if heading is None or heading.get('id') != 'headingWinners'+key or text(heading) != draw.strftime('%m/%d/%Y') or panel.get('aria-labelledby') != heading.get('id'):
            raise ValueError('Conflicting date headings')
        links = panel.xpath('.//a[contains(@href,"Number-Of-Winners-By-Date/Print")]/@href')
        if len(links)!=1: raise ValueError('Missing print date')
        link=urlsplit(links[0])
        if link.path!='/Drawing-Games/Mega-Millions/Number-Of-Winners-By-Date/Print' or link.netloc or parse_qs(link.query)!={'drawDate':[draw.strftime('%m/%d/%Y')+' 00:00:00']}:
            raise ValueError('Conflicting print date')
        tables=panel.xpath('.//table')
        if len(tables)!=1: raise ValueError('Changed dated tables')
        table=tables[0]
        if [text(c) for c in table.xpath('./thead/tr/th')]!=['Matching Numbers','Baseline Prize','Winners','Prize'] or table.xpath('.//*[@colspan or @rowspan]'):
            raise ValueError('Changed columns')
        rows=[]
        for row in table.xpath('./tbody/tr'):
            cells=row.xpath('./td')
            if len(cells)!=4: raise ValueError('Changed report row')
            values=[text(c) for c in cells]
            if not re.fullmatch(r'0|[1-9]\d*', values[2]): raise ValueError('Invalid count')
            rows.append(values)
        if len(rows)!=46 or rows[0][:2]!=['5 + Mega Jackpot',''] or not re.fullmatch(r'\$[0-9,]+\.00',rows[0][3]): raise ValueError('Changed jackpot/row structure')
        categories=[dict(match=rows[0][0],baselinePrize='',publishedCount=int(rows[0][2]),sourcePrize=rows[0][3])]
        for index,(label,base) in enumerate(BASES):
            for offset,multiplier in enumerate(MULTIPLIERS):
                row=rows[1+index*5+offset]
                if row[0]!=label or row[1]!=f'${base:,}' or row[3]!=f'{multiplier}X ${base*multiplier:,}': raise ValueError('Changed match/multiplier/prize identity')
                categories.append(dict(match=label,baselinePrize=row[1],multiplier=multiplier,publishedCount=int(row[2]),sourcePrize=row[3]))
        totals=[]
        for row,multiplier in zip(rows[41:],MULTIPLIERS):
            if row[0:2]!=['Total',''] or row[3]!=f'{multiplier}X': raise ValueError('Changed total identity')
            totals.append(dict(multiplier=multiplier,publishedCount=int(row[2])))
        reports.append(dict(drawDate=draw.isoformat(),categories=categories,sourceMultiplierTotals=totals))
    return dict(game='Mega Millions',sourceUrl=SOURCE,sourceGeography='Delaware',rows=reports,
                coverage='Literal dated source counts and prize labels; prize labels are not actual payout totals. No inferred unique-ticket/person counts, cross-group total or retailer geography. Legacy Megaplier table excluded.')
