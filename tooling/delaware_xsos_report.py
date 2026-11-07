"""Literal Delaware category counts, never an inferred ticket/payout total."""
from datetime import datetime
import re
from lxml import html
from tooling.delaware_multiwin_report import text

SOURCE = 'https://www.delottery.com/Drawing-Games/Powerball-Xs-And-Os/Number-Of-Winners'
LABELS = ['Drawing Date', 'Match 8', 'Match 7', 'Match 6', 'Match 5', 'Match 4']


def parse(raw, *, source_url, observed_date):
    if source_url != SOURCE:
        raise ValueError('Unexpected report source')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != ['Powerball Xs & Os™ - Number of Delaware Winners | Delaware Lottery']:
        raise ValueError('Unexpected report identity/geography')
    tables = tree.xpath('//table')
    if len(tables) != 1:
        raise ValueError('Expected one report table')
    table = tables[0]
    if len(table.xpath('./thead/tr')) != 1 or [text(n) for n in table.xpath('./thead/tr/th')] != LABELS:
        raise ValueError('Changed report columns')
    if any(n.get('colspan') or n.get('rowspan') for n in table.xpath('.//th|.//td')):
        raise ValueError('Unexpected merged cells')
    rows, previous = [], None
    for row in table.xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if len(cells) != 6 or [n.get('data-label') for n in cells] != LABELS:
            raise ValueError('Changed report row')
        values = [text(n) for n in cells]
        if not re.fullmatch(r'[0-9]{2}/[0-9]{2}/[0-9]{4}', values[0]):
            raise ValueError('Invalid date')
        draw = datetime.strptime(values[0], '%m/%d/%Y').date()
        if draw > observed_date or (previous is not None and draw >= previous):
            raise ValueError('Future/duplicate/unordered date')
        previous = draw
        if any(not re.fullmatch(r'0|[1-9][0-9]*', v) for v in values[1:]):
            raise ValueError('Invalid published count')
        rows.append({'drawDate': draw.isoformat(), 'categories': [
            {'label': label, 'publishedCount': int(value)}
            for label, value in zip(LABELS[1:], values[1:])]})
    if not rows:
        raise ValueError('Empty report')
    return {'sourceUrl': SOURCE, 'game': 'Powerball Xs & Os',
            'sourceGeography': 'Delaware', 'sourceUnit': 'Number of Delaware Winners',
            'rows': rows, 'coverage': 'Literal published category counts; no inferred unique-ticket total, payout, retailer join or within-state location.'}
