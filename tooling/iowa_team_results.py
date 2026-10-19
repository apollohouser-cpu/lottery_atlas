"""Iowa Xs & Os results as literal source team codes, not positional alt labels."""
from datetime import date, datetime
import re
from lxml import html
from tooling.iowa_draw_results import plain

# Source image-code vocabulary; preserve abbreviations without guessed full names.
TEAM_CODES = frozenset('ARI ATL BAL BUF CAR CHI CIN CLE DAL DEN DET GB HOU IND JAX KC LV LAC LAR MIA MIN NE NO NYG NYJ PHI PIT SF SEA TB TEN WAS'.split())
SOURCE = 'https://www.ialottery.com/Pages/Games-Online/PowerballXOWin.aspx'

def parse_team_results(raw, *, as_of):
    if type(as_of) is not date:
        raise ValueError('Explicit local date required')
    tree = html.fromstring(raw)
    tables = tree.xpath('//table[@id="colorPBXO"]')
    if len(tables) != 1:
        raise ValueError('Missing or ambiguous XsOs table')
    rows = tables[0].xpath('./tr|./thead/tr|./tbody/tr')
    if rows and rows[-1].get('class') == 'footercolor' and not plain(rows[-1]) and len(rows[-1].xpath('./td')) == 1:
        rows = rows[:-1]
    if len(rows)<3 or [plain(c) for c in rows[0].xpath('./th')] != ['Date','Teams']:
        raise ValueError('Changed team table header or insufficient history')
    results=[]
    for row in rows[1:]:
        cells=row.xpath('./td')
        if len(cells)!=2:
            raise ValueError('Malformed team result row')
        raw_date=plain(cells[0])
        if not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}',raw_date):
            raise ValueError('Invalid date')
        day=datetime.strptime(raw_date,'%m/%d/%Y').date()
        if day>as_of or day<date(2026,2,22) or (results and day.isoformat()>=results[-1]['drawDate']):
            raise ValueError('Future, old, duplicate or unordered date')
        images=cells[1].xpath('.//img')
        if len(images)!=8 or plain(cells[1])!='- - - - - - -':
            raise ValueError('Expected exactly eight team images')
        codes=[];sources=[]
        for position,img in enumerate(images,1):
            m=re.fullmatch(r'/images/game-logos/PBXO_Teams/([A-Z]{2,3})\.png',img.get('src',''))
            if not m or m[1] not in TEAM_CODES or img.get('alt')!='Team '+str(position):
                raise ValueError('Unknown team image identity/position')
            codes.append(m[1]);sources.append('https://www.ialottery.com'+img.get('src'))
        if len(set(codes))!=8:
            raise ValueError('Duplicate team')
        results.append(dict(group='xsos',drawDate=day.isoformat(),sourceDateText=raw_date,
                            teamCodes=codes,teamImageSources=sources,sourceUrl=SOURCE,
                            teamLabel='Official source team abbreviations'))
    return results[:2]
