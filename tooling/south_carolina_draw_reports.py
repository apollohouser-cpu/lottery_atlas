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
        date = re.search(r'<span\b[^>]*>(\d+/\d+/\d+)</span>', section)
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

XO_SOURCE = 'https://www.sceducationlottery.com/Games/PowerballXO'
PALMETTO_SOURCE = 'https://www.sceducationlottery.com/Games/PalmettoCash5'


def _count_table(table, headers, tier_names, count_columns):
    actual = [clean(x) for x in re.findall(r'<th[^>]*>(.*?)</th>', table, re.S)]
    if actual != headers:
        raise ValueError('Unexpected report columns')
    rows = [[clean(c) for c in re.findall(r'<td\b[^>]*>(.*?)</td>', row, re.S)] for row in re.findall(r'<tr[^>]*>(.*?)</tr>', table, re.S)]
    rows = [r for r in rows if r]
    if len(rows) != len(tier_names) + 1 or any(len(r) != len(headers) for r in rows):
        raise ValueError('Incomplete report rows')
    if [r[0] for r in rows[:-1]] != tier_names or rows[-1][0] != 'Total Winning Tickets':
        raise ValueError('Unexpected tiers')
    for column in count_columns:
        if sum(count(r[column]) for r in rows[:-1]) != count(rows[-1][column]):
            raise ValueError('Tier counts do not reconcile')
    if len(count_columns) == 2 and any(count(r[count_columns[0]]) != count(r[count_columns[1]]) for r in rows):
        raise ValueError('Winner and total columns differ')
    return rows


def _finish_reports(reports):
    dates = [r['drawDate'] for r in reports]
    if not dates or dates != sorted(set(dates), reverse=True):
        raise ValueError('Missing, duplicate or unordered draws')
    return reports


def _report(game, day, source, headers, rows, note):
    return {'gameName': game, 'drawDate': day.isoformat(), 'drawingSession': None,
            'sourceUrl': source, 'sourcePublicationDate': None, 'headers': headers,
            'tiers': rows[:-1], 'reportedTotals': rows[-1],
            'reportedWinners': count(rows[-1][-1]), 'reportedPayout': None,
            'tableNote': note + ' Statewide only; no retailer or county allocation. Do not add to claim counts.'}


def parse_powerball_xo(raw):
    reports = []
    for section in raw.split('<div class="drawResultsaccordion">')[1:]:
        date = re.search(r'<span\b[^>]*>(\d+/\d+/\d+)</span>', section)
        table = re.search(r'<table[^>]*>(.*?)</table>', section, re.S)
        scope = re.search(r'This table represents (.*?), South Carolina winners ONLY', section)
        if not date or not table or not scope:
            raise ValueError('Missing Xs and Os provenance')
        day = datetime.strptime(date[1], '%m/%d/%Y').date()
        if datetime.strptime(clean(scope[1]), '%B %d, %Y').date() != day:
            raise ValueError('Xs and Os date mismatch')
        headers = ['Match', 'Powerball Xs & 0s™ Prizes', 'Total Winners']
        rows = _count_table(table[1], headers, ['Jackpot (Match 8)', 'Match 7', 'Match 6', 'Match 5', 'Match 4'], [2])
        reports.append(_report('Powerball Xs & Os', day, XO_SOURCE, headers, rows,
            'Prize amounts are preserved as published for each drawing, including historical variations. Exact payout is not established.'))
    return _finish_reports(reports)


def parse_palmetto(raw):
    reports = []
    for date, table in re.findall(r'<div class="text-center lightblue-bg">\s*([A-Za-z]+ \d+, \d{4})\s*</div>.*?<table class="small-table">(.*?)</table>', raw, re.S):
        day = datetime.strptime(date, '%B %d, %Y').date()
        headers = ['Match', 'Prizes', 'Winners', 'Total']
        rows = _count_table(table, headers, ['Match 5', 'Match 4', 'Match 3', 'Match 2'], [2, 3])
        reports.append(_report('Palmetto Cash 5', day, PALMETTO_SOURCE, headers, rows,
            'Source-listed tier amounts retained. Multiplier distribution and exact payout are not supplied; winner and total columns are not added together.'))
    return _finish_reports(reports)

CASH_POP_SOURCE = 'https://www.sceducationlottery.com/Games/CashPOP'


def parse_cash_pop(raw):
    from decimal import Decimal
    reports = []
    keys = []
    for section in raw.split('<div class="table-heading">')[1:]:
        table = re.search(r'<table class="table-bordered"[^>]*>(.*?)</table>', section, re.S)
        if not table:
            raise ValueError('Missing CASH POP session totals')
        heading = clean(section[:table.start()])
        date = re.search(r'([A-Za-z]+ \d+, \d{4})', heading)
        sessions = re.findall(r'\b(Midday|Evening)\b', heading)
        if not date or len(sessions) != 1:
            raise ValueError('Missing CASH POP date/session')
        day = datetime.strptime(date[1], '%B %d, %Y').date()
        session = sessions[0]
        rows = [[clean(c) for c in re.findall(r'<td\b[^>]*>(.*?)</td>', row, re.S)] for row in re.findall(r'<tr[^>]*>(.*?)</tr>', table[1], re.S)]
        if len(rows) != 2 or any(len(row) != 2 for row in rows) or [r[0] for r in rows] != ['Total Winners:', 'Total Payout:']:
            raise ValueError('Unexpected CASH POP totals')
        winners = count(rows[0][1])
        payout = rows[1][1]
        if not re.fullmatch(r'\$(?:\d+|\d{1,3}(?:,\d{3})+)\.\d{2}', payout):
            raise ValueError('Invalid CASH POP payout')
        amount = Decimal(payout.replace('$', '').replace(',', ''))
        if (winners == 0) != (amount == 0):
            raise ValueError('Inconsistent CASH POP zero totals')
        reports.append({'gameName': 'CASH POP', 'drawDate': day.isoformat(), 'drawingSession': session,
                        'sourceUrl': CASH_POP_SOURCE, 'sourcePublicationDate': None,
                        'headers': ['Scope', 'Reported winners', 'Reported payout'], 'tiers': [],
                        'reportedTotals': ['Session total', rows[0][1], payout],
                        'reportedWinners': winners, 'reportedPayout': float(amount),
                        'tableNote': 'Official statewide session totals only; no actual prize-tier breakdown or retailer allocation. Odds tables are not winner counts. Do not add to claim records.'})
        keys.append((day.isoformat(), 1 if session == 'Evening' else 0))
    if not keys or keys != sorted(set(keys), reverse=True):
        raise ValueError('Missing, duplicate or unordered CASH POP sessions')
    return reports
