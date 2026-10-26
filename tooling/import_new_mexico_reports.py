"""Exact-date New Mexico reports; literal source count units, never people."""
from datetime import datetime
import re
from lxml import html

DP_SOURCE = 'https://www.nmlottery.com/rts/games/powerball-2015/table-double-play.aspx'
DP_MATCHES = ['5 White Balls + Powerball', '5 White Balls', '4 White Balls + Powerball',
              '4 White Balls', '3 White Balls + Powerball', '3 White Balls',
              '2 White Balls + Powerball', '1 White Ball + Powerball', 'Powerball']
DP_PRIZES = ['$10,000,000', '$500,000', '$50,000', '$500', '$500', '$20', '$20', '$10', '$7']


def plain(node):
    return ' '.join(node.text_content().split())


def integer(text):
    if not re.fullmatch(r'(?:0|[1-9][0-9]*|[1-9][0-9]{0,2}(?:,[0-9]{3})+)', text):
        raise ValueError('Invalid report count')
    return int(text.replace(',', ''))


def money(text):
    if not text.startswith('$'):
        raise ValueError('Missing dollar value')
    return integer(text[1:])


def table_rows(table):
    if table.xpath('.//table'):
        raise ValueError('Nested report table')
    result = []
    for row in table.xpath('./tr|./thead/tr|./tbody/tr|./tfoot/tr'):
        cells = row.xpath('./th|./td')
        if any(c.get('colspan','1') != '1' or c.get('rowspan','1') != '1' for c in cells):
            raise ValueError('Changed report cell span')
        result.append([plain(c) for c in cells])
    return result


def parse_double_play(raw, draw):
    """Require an independently validated matching DP result before attachment."""
    if draw.get('game') != 'powerball' or draw.get('variant') != 'double_play' or draw.get('session') is not None:
        raise ValueError('Report/result variant mismatch')
    tree = html.fromstring(raw)
    headings = tree.xpath('//h2')
    if len(headings) != 1:
        raise ValueError('Missing/duplicate report heading')
    match = re.fullmatch(r"New Mexico's Double Play Results for ([A-Za-z]+ [0-9]{1,2}, [0-9]{4})", plain(headings[0]))
    if not match:
        raise ValueError('Wrong report geography or variant')
    day = datetime.strptime(match[1], '%B %d, %Y').date().isoformat()
    if day != draw.get('date'):
        raise ValueError('Report/result date mismatch')
    tables = tree.xpath('//table')
    if len(tables) != 2:
        raise ValueError('Changed report table count')
    rows, totals = [table_rows(t) for t in tables]
    if len(rows) != 10 or rows[0] != ['Match', 'Prize', 'Winners']:
        raise ValueError('Changed Double Play schema')
    tiers = []
    for i, row in enumerate(rows[1:]):
        if len(row) != 3 or row[:2] != [DP_MATCHES[i], DP_PRIZES[i]]:
            raise ValueError('Changed Double Play tier/schedule')
        tiers.append(dict(match=row[0], prizeLabel=row[1], prizeValue=money(row[1]),
                          sourceWinners=integer(row[2])))
    if len(totals) != 2 or totals[0] != ['Total Prizes Won', 'Total Prize Value'] or len(totals[1]) != 2:
        raise ValueError('Changed report totals schema')
    total_count, total_value = integer(totals[1][0]), money(totals[1][1])
    if total_count != sum(t['sourceWinners'] for t in tiers):
        raise ValueError('Winner columns do not reconcile to source prizes won')
    if total_value != sum(t['sourceWinners'] * t['prizeValue'] for t in tiers):
        raise ValueError('Prize values do not reconcile')
    return dict(game='powerball', variant='double_play', date=day, session=None,
                geography='New Mexico', countUnit='source Winners / prizes won',
                countNote='Source Winners columns reconcile to Total Prizes Won. Not unique people, deduplicated tickets, claims paid or retailer stock.',
                sourceUrl=DP_SOURCE, tiers=tiers, totalPrizesWon=total_count,
                totalPrizeValue=total_value)
