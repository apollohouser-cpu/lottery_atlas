"""Dated Iowa-ticket source reports; never people, claims or inferred zero prizes."""
from datetime import date, datetime
import re
from lxml import html
from tooling.iowa_draw_results import plain

MATCHES = ['5+1','5+0','4+1','4+0','3+1','3+0','2+1','1+1','0+1']
SPECS = {
 'powerball': ('Powerball', 'Rules', ['Jackpot 5+1','$1,000,000 5+0','$50,000 4+1','$100 4+0','$100 3+1','$7 3+0','$7 2+1','$4 1+1','$4 0+1'], ['Jackpot','PP']),
 'double_play': ('Powerball', 'Rules2', ['$10,000,000 5+1','$500,000 5+0','$50,000 4+1','$500 4+0','$500 3+1','$20 3+0','$20 2+1','$10 1+1','$7 0+1'], []),
 'mega_millions': ('Mega Millions', 'Rules', MATCHES, ['Jackpot','MP***']),
 'lotto_america': ('Lotto America', 'Rules', ['Jackpot 5+1','$20,000 5+0','$1,000 4+1','$100 4+0','$20 3+1','$5 3+0','$5 2+1','$2 1+1','$2 0+1'], ['Jackpot','ASB']),
 'millionaire_for_life': ('Millionaire for Life', 'Rules', ['$1M/Year for Life 5+1','$100K/Year for Life 5+0','$7,500 4+1','$500 4+0','$250 3+1','$50 3+0','$25 2+1','$8 2+0','$8 1+1'], []),
 'xsos': ('Powerball Xs & Os', 'Rules', ['Jackpot 8 of 8','$20,000 7 of 8','$500 6 of 8','$40 5 of 8','$7 4 of 8'], ['Jackpot']),
}

def parse_reports(raw, group, *, as_of):
    if group not in SPECS or type(as_of) is not date:
        raise ValueError('Unsupported report group/date')
    game, table_id, tiers, extra = SPECS[group]
    tree = html.fromstring(raw)
    phrase = 'number of winners at each prize level for '+game+' tickets purchased in Iowa.'
    if phrase not in plain(tree):
        raise ValueError('Missing Iowa-ticket geographic/unit qualifier')
    tables = tree.xpath('//table[@id=$id]', id=table_id)
    if len(tables) != 1:
        raise ValueError('Ambiguous report table')
    table = tables[0]
    # Source HTML deliberately has direct th children, not a header tr.
    if [plain(c) for c in table.xpath('./th')] != ['Draw Date']+tiers+extra:
        raise ValueError('Changed report columns')
    rows = table.xpath('./tr')
    if not rows:
        raise ValueError('Empty report')
    reports = {}
    previous = None
    for row in rows:
        c = [plain(x) for x in row.xpath('./td')]
        if len(c) != 1+len(tiers)+len(extra):
            raise ValueError('Malformed report row')
        if not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}', c[0]):
            raise ValueError('Invalid date')
        day = datetime.strptime(c[0], '%m/%d/%Y').date()
        if day > as_of or day < date(2026,2,22) or (previous and day >= previous):
            raise ValueError('Future, old, duplicate or unordered report date')
        previous = day
        values = c[1:1+len(tiers)]
        if any(not re.fullmatch(r'0|[1-9]\d*', x) for x in values):
            raise ValueError('Invalid winner count')
        record = dict(group=group, drawDate=day.isoformat(), sourceDateText=c[0],
                      countLabel='Winners for tickets purchased in Iowa (source label)',
                      tiers=[dict(sourceTierLabel=k, sourceWinners=int(v)) for k,v in zip(tiers,values)])
        for name, value in zip(extra,c[1+len(tiers):]):
            if name == 'Jackpot':
                if not re.fullmatch(r'\$(?:0|[1-9]\d{0,2}(?:,\d{3})*|[1-9]\d*)',value):
                    raise ValueError('Invalid jackpot field')
                amount = int(value[1:].replace(',',''))
                record['sourceJackpotText'] = value
                record['advertisedJackpotDollars'] = amount if amount else None
                if not amount:record['jackpotLimitation'] = 'Source zero placeholder; advertised prize unavailable'
            elif name == 'MP***':
                if value != '':raise ValueError('Unexpected modern shared Megaplier')
            else:
                permitted = ('2','3','4','5','10') if name=='PP' else ('2','3','4','5')
                if value not in permitted:raise ValueError('Invalid option multiplier')
                record['multiplier'] = int(value)
        reports[day.isoformat()] = record
    return reports

def attach_report(result, reports):
    """Exact date+group only. Missing reports are unavailable, never zero."""
    report = reports.get(result['drawDate'])
    if report is None:
        return {**result, 'report':None, 'reportLimitation':'No validated report for this exact date and group'}
    if report['group'] != result['group'] or report['drawDate'] != result['drawDate']:
        raise ValueError('Report/result identity mismatch')
    if 'multiplier' in report and report['multiplier'] != result.get('multiplier'):
        raise ValueError('Report/result multiplier mismatch')
    return {**result,'report':report}
