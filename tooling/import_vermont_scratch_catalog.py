"""Import Vermont's unpaginated report, claim dates and verified detail inventory."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
import time
from lxml import html
from zoneinfo import ZoneInfo

ROOT = 'https://vtlottery.com'
SOURCE = ROOT + '/games/instant-tickets/outstanding-prizes'
DEADLINES = ROOT + '/games/instant-tickets/last-day-to-redeem'


def text(node):
    return ' '.join(node.text_content().split())


def number(value):
    if not re.fullmatch(r'\$?(?:\d+|\d{1,3}(?:,\d{3})+)', value):
        raise ValueError('Invalid nonnegative integer')
    return int(value.replace('$', '').replace(',', ''))


def table(raw, headers):
    root = html.fromstring(raw)
    tables = root.xpath('//table[@id="tblData"]')
    if len(tables) != 1 or [text(x) for x in tables[0].xpath('./thead/tr/th')] != headers:
        raise ValueError('Missing table or changed headers')
    rows = tables[0].xpath('./tbody/tr')
    if not rows:
        raise ValueError('Empty source table')
    return rows


def parse_report(raw):
    rows = table(raw, ['Price', 'Game #', 'Game Name', 'Top Prizes', 'Unclaimed Top Prizes', 'Total Unclaimed', '% Sold', '# Of Tickets'])
    games = {}
    for row in rows:
        cells = row.xpath('./td')
        if len(cells) != 8:
            raise ValueError('Incomplete report row')
        price, gid, name, prizes, counts, dollars, sold, tickets = cells
        gid = text(gid)
        if not gid.isdigit() or gid in games:
            raise ValueError('Duplicate or invalid printed identity')
        amounts = [number(s.strip()) for s in prizes.itertext() if s.strip()]
        remaining = [number(s.strip()) for s in counts.itertext() if s.strip()]
        if not amounts or len(amounts) != len(remaining) or len(set(amounts)) != len(amounts) or min(amounts) <= 0:
            raise ValueError('Invalid parallel prize/count lists')
        links = name.xpath('./a/@href')
        if len(links) != 1 or not re.fullmatch(r'/[a-z0-9/-]+', links[0]) or links[0].startswith('//') or not text(name):
            raise ValueError('Invalid detail link or name')
        cost = number(text(price))
        if cost <= 0 or number(text(tickets)) <= 0 or number(text(sold)) > 100:
            raise ValueError('Invalid price/printed count/percent sold')
        number(text(dollars))  # Never interpret dollars or printed tickets as winners.
        games[gid] = dict(id=gid, name=text(name), path=links[0], price=cost,
                          tiers=[dict(prizeAmount=p, remaining=n) for p, n in zip(amounts, remaining)])
    return games


def parse_date(value):
    if value == 'TBD':
        return None
    return datetime.strptime(value, '%m/%d/%Y' if len(value.split('/')[-1]) == 4 else '%m/%d/%y').date()


def parse_deadlines(raw):
    rows = table(raw, ['Game #', 'Game Name', 'Top Prize', 'Game Start', 'Game End', '% Sold', 'Last Day to Redeem'])
    games = {}
    for row in rows:
        cells = [text(x) for x in row.xpath('./td')]
        if len(cells) != 7:
            raise ValueError('Incomplete deadline row')
        gid, name, top, start, end, sold, claim = cells
        if not gid.isdigit() or gid in games:
            raise ValueError('Duplicate deadline identity')
        games[gid] = dict(top=number(top), start=parse_date(start), end=parse_date(end), claim=parse_date(claim))
    return games


def parse_detail(raw, game, dates, today):
    gid = game['id']
    if gid not in dates:
        raise ValueError('Game missing deadline record')
    d = dates[gid]
    if d['start'] is None or (d['end'] and d['claim'] and d['claim'] < d['end']):
        raise ValueError('Invalid eligibility dates')
    if d['start'] > today or (d['claim'] and d['claim'] < today):
        return None
    root = html.fromstring(raw)
    def fields(name):
        return root.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," field-name-' + name + ' ")]')
    def field(name):
        found = fields(name)
        if len(found) != 1:
            raise ValueError('Missing or ambiguous detail field: ' + name)
        values = found[0].xpath('.//*[contains(concat(" ",normalize-space(@class)," ")," field-item ")]')
        if len(values) != 1:
            raise ValueError('Missing detail value')
        return text(values[0])
    if field('field-game-id') != gid or number(field('field-price')) != game['price']:
        raise ValueError('Identity or price mismatch')
    top = root.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," instant-ticket-right-half ")]/h3/span[@class="fieldAsTitle"]')
    if len(top) != 1 or number(text(top[0])) != d['top'] or d['top'] != max(t['prizeAmount'] for t in game['tiers']):
        raise ValueError('Top-prize mismatch')
    start = parse_date(field('field-ticket-start-date'))
    claim = parse_date(field('field-last-day-to-cash')) if fields('field-last-day-to-cash') else None
    if start != d['start'] or claim != d['claim']:
        raise ValueError('Detail/deadline mismatch')
    tiers = []
    for f in fields('field-unclaimed-top-prizes'):
        label, value = f.xpath('./div[@class="field-label"]'), f.xpath('.//div[@class="field-item"]')
        if len(label) != 1 or len(value) != 1:
            raise ValueError('Invalid detail tier')
        tiers.append(dict(prizeAmount=number(text(label[0])), remaining=number(text(value[0]))))
    if len({t['prizeAmount'] for t in tiers}) != len(tiers) or sorted(tiers, key=lambda t: t['prizeAmount']) != sorted(game['tiers'], key=lambda t: t['prizeAmount']):
        raise ValueError('Report/detail tier disagreement')
    if number(field('field-number-of-tickets')) <= 0 or number(field('field__of-tickets-sold')) > 100:
        raise ValueError('Invalid detail inventory metadata')
    note = 'Published unclaimed top-tier inventory only; source verification date and update cadence are not published. Retrieval time does not establish inventory freshness. Not dated winning-ticket counts or verified store stock.'
    if d['end']:
        note += f' Published game end: {d["end"].isoformat()}.'
    if claim:
        note += f' Last day to redeem: {claim.isoformat()}.'
    result = dict(stateName='Vermont', id=gid, name=game['name'], cost=game['price'], topPrize=d['top'],
                  topPrizesRemaining=next(t['remaining'] for t in tiers if t['prizeAmount'] == d['top']),
                  sourceUrl=ROOT + game['path'], sourceDate=None, startDate=start.isoformat(),
                  prizeTiers=tiers, inventoryNote=note)
    if claim:
        result['lastDayToRedeem'] = claim.isoformat()
    if d['end']:
        result['endDate'] = d['end'].isoformat()
    return result


def fetch(url):
    for attempt in range(4):
        try:
            return subprocess.run(['curl', '-fsSL', '--max-time', '30', '--retry', '3', url], capture_output=True, check=True).stdout
        except subprocess.CalledProcessError as error:
            if error.returncode not in {6, 7} or attempt == 3:
                raise
            time.sleep(attempt + 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    now = datetime.now(ZoneInfo('America/New_York'))
    games = parse_report(fetch(SOURCE))
    dates = parse_deadlines(fetch(DEADLINES))
    with ThreadPoolExecutor(max_workers=2) as pool:
        parsed = list(pool.map(lambda g: parse_detail(fetch(ROOT + g['path']), g, dates, now.date()), games.values()))
    eligible = sorted([g for g in parsed if g], key=lambda g: int(g['id']))
    if len(eligible) < 30:
        raise ValueError('Unexpectedly small eligible catalog')
    catalog = dict(state='Vermont', source=SOURCE, sourceDate=None,
                   coverage='Unpaginated outstanding-prizes report with detail and deadline joins; listed top tiers only. Includes games with an announced end date until their last redemption date. Not dated claims or retailer-linked activity.',
                   updateCadence='Publication cadence unconfirmed; checked every six hours.', games=eligible)
    result = dict(source='Vermont official detail-verified unclaimed top-tier inventory', updatedAt=now.isoformat(), catalogs=[catalog])
    if args.output.exists():
        old = json.loads(args.output.read_text())
        if old.get('catalogs') == result['catalogs']:
            result['updatedAt'] = old['updatedAt']
    temp = args.output.with_suffix('.tmp')
    temp.write_text(json.dumps(result, indent=2) + '\n')
    temp.replace(args.output)
    print(f'Validated {len(eligible)} eligible Vermont games')


if __name__ == '__main__':
    main()
