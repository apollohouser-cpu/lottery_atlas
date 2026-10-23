"""Exact-date Idaho MFL HTML report; never reuse latest counts on older results."""
from datetime import datetime
import re
from lxml import html
from tooling.idaho_mfl_results import parse_results, SOURCE

TIERS = list(zip(
    ['XXXXXY', 'XXXXX', 'XXXXY', 'XXXX', 'XXXY', 'XXX', 'XXY', 'XX', 'XY'],
    ['$1,000,000 a year, FOR LIFE', '$100,000 a year, FOR LIFE', '$7,500', '$500', '$250', '$50', '$25', '$8', '$8']))


def parse_report(raw, requested_date, *, as_of=None):
    results = parse_results(raw, as_of=as_of)
    if requested_date not in {r['drawDate'] for r in results}:
        raise ValueError('Report requested outside validated result window')
    tree = html.fromstring(raw)
    tables = tree.xpath('//table[contains(concat(" ",normalize-space(@class)," ")," idaho-table ")]')
    if len(tables) != 1:
        raise ValueError('Missing/ambiguous Idaho report')
    table = tables[0]
    dates = table.getparent().xpath('./div/input[@data-game="Millionaire For Life"][@data-region="idaho"]/@value')
    if len(dates) != 1 or not re.fullmatch(r'[0-9]{2}/[0-9]{2}/[0-9]{2}', dates[0]):
        raise ValueError('Missing Idaho report date')
    report_date = datetime.strptime(dates[0], '%m/%d/%y').date().isoformat()
    if report_date not in {r['drawDate'] for r in results}:
        raise ValueError('Report date lacks matching result')
    if [' '.join(x.text_content().split()) for x in table.xpath('./thead/tr/th')] != ['Match', 'Prize Amount', 'Millionaire For Life']:
        raise ValueError('Changed report headers')
    rows = table.xpath('./tbody/tr')
    if len(rows) != len(TIERS):
        raise ValueError('Incomplete report')
    tiers = []
    for row, (match, prize) in zip(rows, TIERS):
        cells = row.xpath('./td')
        if len(cells) != 3 or row.get('data-number') != match or row.get('data-prize') != prize:
            raise ValueError('Changed report identity')
        if ' '.join(cells[1].text_content().split()) != prize or cells[2].get('class') != 'millionaire_for_life':
            raise ValueError('Changed prize/count cell')
        count = cells[2].text_content().strip()
        if not re.fullmatch(r'[0-9]+', count) or int(count) > 9007199254740991:
            raise ValueError('Malformed report count')
        tiers.append(dict(sourceMatch=match, prizeLabel=prize, publishedWinnerCount=int(count)))
    if requested_date != report_date:
        return None
    return dict(drawDate=report_date, sourceUrl=SOURCE, sourceLabel='Idaho Winners',
                countDefinition='Published Idaho prize-tier winner counts; distinct tickets and people are not established.',
                tiers=tiers)
