"""Literal session report; mobile duplicate totals are never summed."""
from datetime import datetime
import re
from lxml import html
from tooling.delaware_multiwin_report import text

CATEGORIES = {
3:['Straight','3-Way Box','6-Way Box','Front Pair','Back Pair','Straight/Box 6-Way','Straight/Box 3-Way','3-Way Combination','6-Way Combination'],
4:['Straight','Box 24','Box 12','Box 6','Box 4','Straight/Box 24','Straight/Box 12','Straight/Box 6','Straight/Box 4','Combo 24','Combo 12','Combo 6','Combo 4'],
5:['Straight','Boxed','Front 4','Back 4','Front 3','Back 3','Front Pair','Back Pair']}


def parse(raw, *, digits, source_url, observed_date):
    if digits not in CATEGORIES or source_url!=f'https://www.delottery.com/Drawing-Games/Play-{digits}/Number-Of-Winners':
        raise ValueError('Wrong source')
    tree=html.fromstring(raw)
    if tree.xpath('//title/text()')!=[f'Number Of Winners - Play {digits} - Drawing Games | Delaware Lottery']:
        raise ValueError('Wrong report identity')
    tables=tree.xpath('//table')
    if len(tables)!=1:raise ValueError('Changed tables')
    table=tables[0];headers=table.xpath('./thead/tr')
    if len(headers)!=2 or [text(c) for c in headers[1].xpath('./th')]!=['Match','50¢ Bet Wins','Number of Winners']:
        raise ValueError('Changed headers')
    title=text(headers[0]);match=re.fullmatch(rf'Play {digits} on ([0-9]{{1,2}}/[0-9]{{1,2}}/[0-9]{{4}})',title)
    icons=headers[0].xpath('.//i')
    if not match or len(icons)!=1 or icons[0].get('aria-label') not in ('Day','Night'):
        raise ValueError('Missing session/date')
    session=icons[0].get('aria-label');classes=icons[0].get('class','').split()
    if ('li-sun' in classes)!= (session=='Day') or ('li-moon' in classes)!=(session=='Night'):
        raise ValueError('Conflicting session markers')
    draw=datetime.strptime(match[1],'%m/%d/%Y').date()
    if draw>observed_date:raise ValueError('Future report')
    rows=table.xpath('./tbody/tr');first=rows[0].xpath('./td')
    if len(first)!=1 or first[0].get('data-label')!='Drawing Type' or text(first[0])!=f'Play{digits}{session} on {match[1]}':
        raise ValueError('Conflicting mobile session/date')
    categories=[];totals={}
    for row in rows[1:]:
        cells=row.xpath('./td');labels=[c.get('data-label') for c in cells];values=[text(c) for c in cells]
        if labels==['Match','50¢ Bet Wins','Number of Winners']:
            if not re.fullmatch(r'[0-9]+',values[2]) or not re.fullmatch(r'\$[0-9,]+|Varies',values[1]):raise ValueError('Invalid report values')
            categories.append(dict(label=values[0],source50CentBetWins=values[1],publishedCount=int(values[2])))
        else:
            if labels not in ([None,None,'Total Winners'],[None,None,'Total Won'],['Total Winners','Total Won'],['Total Winners']):raise ValueError('Unknown summary structure')
            if labels[0] is None and (values[0]!='' or values[1]!=labels[2]+':'):raise ValueError('Changed summary label')
            for label,value in zip(labels,values):
                if label is None:continue
                if not re.fullmatch(r'[0-9]+' if label=='Total Winners' else r'\$[0-9,]+',value):raise ValueError('Invalid summary value')
                if label in totals and totals[label]!=value:raise ValueError('Conflicting responsive totals')
                totals[label]=value
    if [c['label'] for c in categories]!=CATEGORIES[digits] or 'Total Winners' not in totals:raise ValueError('Missing categories/totals')
    return dict(sourceUrl=source_url,game=f'Play {digits}',session=session.lower(),drawDate=draw.isoformat(),categories=categories,sourceTotals=totals,coverage='Literal published Number of Winners categories and source totals only; unique people/tickets, geography and wager-normalization unverified. Do not compute payouts by multiplying 50-cent schedule values. Missing Total Won remains unavailable.')
