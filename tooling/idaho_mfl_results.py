"""Bounded MFL HTML results; the generic check-number form is not a source."""
from datetime import datetime
import re
from zoneinfo import ZoneInfo
from lxml import html

SOURCE = 'https://www.idaholottery.com/games/draw/millionaire-for-life'


def parse_results(raw, *, as_of=None):
    tree = html.fromstring(raw)
    if tree.xpath('//head/title/text()') != ['Millionaire For Life | Idaho Lottery']:
        raise ValueError('Wrong MFL page')
    tables = tree.xpath('//*[@id="tab4"]//table')
    if len(tables) != 1:
        raise ValueError('Missing/ambiguous history table')
    table = tables[0]
    if [' '.join(x.text_content().split()) for x in table.xpath('./thead/tr/th')] != ['Date', 'Winning Numbers', 'Jackpot']:
        raise ValueError('Changed history headers')
    today = as_of or datetime.now(ZoneInfo('America/Boise')).date()
    results = []
    for row in table.xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if len(cells) != 3 or [c.get('data-title') for c in cells] != ['Date', 'Winning Numbers', 'Jackpot']:
            raise ValueError('Malformed history row')
        date_text = cells[0].text_content().strip()
        if not re.fullmatch(r'[0-9]{2}/[0-9]{2}/[0-9]{2}', date_text):
            raise ValueError('Malformed drawing date')
        draw_date = datetime.strptime(date_text, '%m/%d/%y').date()
        if draw_date > today or (results and draw_date.isoformat() >= results[-1]['drawDate']):
            raise ValueError('Future, duplicate or unordered history')
        lists = cells[1].xpath('./ul')
        if len(lists) != 1 or lists[0].get('class') != 'list-numbers list-numbers--bordered Millionaire For Life':
            raise ValueError('Wrong result identity')
        numbers = [x.text_content().strip() for x in lists[0].xpath('./li')]
        if len(numbers) != 6 or any(not re.fullmatch(r'[0-9]{2}', v) for v in numbers):
            raise ValueError('Malformed MFL numbers')
        if len(set(numbers[:5])) != 5 or any(not 1 <= int(v) <= 58 for v in numbers[:5]) or not 1 <= int(numbers[5]) <= 5:
            raise ValueError('Invalid MFL numbers')
        results.append(dict(group='millionaire-for-life', game='Millionaire For Life',
                            drawDate=draw_date.isoformat(), numbers=numbers[:5],
                            specialNumber=numbers[5], sourceUrl=SOURCE))
    if len(results) < 2:
        raise ValueError('Two dated results required')
    # Validate the complete source table before taking the bounded window.
    # Its generic Jackpot cell is not a verified cash or annuity contract.
    return results[:2]
