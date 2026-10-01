"""Validated SC statewide draw tables; never retailer activity."""
import html
import re
from datetime import datetime

MEGA_SOURCE = 'https://www.sceducationlottery.com/Games/MegaMillions'


def clean(value):
    return ' '.join(html.unescape(re.sub(r'<[^>]+>', ' ', value)).split())


def count(value):
    if not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)', value):
        raise ValueError('Invalid winner count')
    return int(value.replace(',', ''))


def parse_mega_millions(raw):
    reports = []
    sections = raw.split('<div class="drawResultsaccordion">')[1:]
    if not sections:
        raise ValueError('Missing draw results')
    for section in sections:
        date = re.search(r'<span>(\d+/\d+/\d+)</span>', section)
        table = re.search(r'<table[^>]*>(.*?)</table>', section, re.S)
        scope = re.search(r'This table represents (.*?), South Carolina winners ONLY', section)
        if not date or not table or not scope:
            raise ValueError('Missing draw provenance')
        day = datetime.strptime(date[1], '%m/%d/%Y').date()
        if datetime.strptime(clean(scope[1]), '%B %d, %Y').date() != day:
            raise ValueError('Scope date differs from draw date')
        headers = [clean(x) for x in re.findall(r'<th[^>]*>(.*?)</th>', table[1], re.S)]
        expected = ['Match', 'Base Prize (For Reference Only)', 'Prize Amount', 'Prize Winners']
        if headers != expected:
            raise ValueError('Unexpected Mega Millions columns')
        rows = [[clean(c) for c in re.findall(r'<td\b[^>]*>(.*?)</td>', row, re.S)] for row in re.findall(r'<tr[^>]*>(.*?)</tr>', table[1], re.S)]
        rows = [row for row in rows if row]
        if len(rows) != 10 or any(len(row) != 4 for row in rows[:-1]) or len(rows[-1]) != 2 or rows[-1][0] != 'Total Prize Winners':
            raise ValueError('Incomplete Mega Millions tiers')
        if len({row[0] for row in rows[:-1]}) != 9:
            raise ValueError('Duplicate tier')
        total = count(rows[-1][1])
        if sum(count(row[-1]) for row in rows[:-1]) != total:
            raise ValueError('Tier counts do not reconcile')
        reports.append({'gameName': 'Mega Millions', 'drawDate': day.isoformat(), 'drawingSession': None,
                        'sourceUrl': MEGA_SOURCE, 'sourcePublicationDate': None,
                        'headers': headers, 'tiers': rows[:-1],
                        'reportedTotals': ['Total Prize Winners', '', '', rows[-1][1]],
                        'reportedWinners': total, 'reportedPayout': None,
                        'tableNote': 'South Carolina statewide prize winners for this draw only. Prize ranges do not establish exact payout. No retailer or county allocation; do not add these counts to claim records.'})
    dates = [r['drawDate'] for r in reports]
    if len(set(dates)) != len(dates) or dates != sorted(dates, reverse=True):
        raise ValueError('Duplicate or unordered draws')
    return reports
