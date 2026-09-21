"""Import current Idaho Scratch games; remaining prizes below $25 stay unknown."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html

ROOT = 'https://www.idaholottery.com'
SOURCE = ROOT + '/games/scratch'
CLAIMS = ROOT + '/games/claim-scratch'


def text(node):
    return ' '.join(node.text_content().split())


def one(node, xpath):
    values = node.xpath(xpath)
    if len(values) != 1:
        raise ValueError('Missing or ambiguous source field: ' + xpath)
    return values[0]


def number(value):
    if not re.fullmatch(r'\$?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.00)?', value):
        raise ValueError('Invalid integer amount/count: ' + value)
    return int(value.replace('$', '').replace(',', '').split('.')[0])


def parse_catalog(raw):
    tree = html.fromstring(raw)
    if tree.xpath('//*[contains(@class,"pager__item--next")]'):
        raise ValueError('Unexpected pagination')
    games = {}
    for card in tree.xpath('//li[@data-game-id]'):
        gid = card.get('data-game-id')
        if not gid.isdigit() or gid in games:
            raise ValueError('Invalid or duplicate catalog ID')
        name = text(one(card, './/h5'))
        path = one(card, './/a[@class="image-link"]/@href')
        if not name or not re.fullmatch(r'/games/scratch/[a-z0-9-]+', path):
            raise ValueError('Invalid game identity/link')
        price = number(text(one(card, './/span[@class="game__info-price"]')))
        top = number(one(card, './/span[@class="game__info-top-prize-value"]').text.strip())
        table = one(card, './/table[@class="scratch-prizes"]')
        if [text(x) for x in table.xpath('./thead/tr/th')] != ['Prize', 'Remaining']:
            raise ValueError('Changed catalog tier headers')
        tiers = {}
        for row in table.xpath('./tbody/tr'):
            cells = row.xpath('./td')
            if len(cells) != 2:
                raise ValueError('Malformed catalog tier')
            amount, remaining = map(lambda c: number(text(c)), cells)
            if amount < 25 or amount in tiers:
                raise ValueError('Unexpected or duplicate inventory tier')
            tiers[amount] = remaining
        if not tiers or min(price, top) <= 0 or max(tiers) != top:
            raise ValueError('Missing or conflicting top prize')
        games[gid] = dict(id=gid, name=name, path=path, cost=price, topPrize=top, tiers=tiers)
    if not games:
        raise ValueError('Empty catalog')
    return games


def parse_claims(raw):
    table = one(html.fromstring(raw), '//table')
    if [text(x) for x in table.xpath('./thead/tr/th')] != ['Number', 'Game Name', 'Official Game End', 'Last Day to Claim']:
        raise ValueError('Changed claim-date headers')
    result = {}
    for row in table.xpath('./tbody/tr'):
        cells = [text(c) for c in row.xpath('./td')]
        if len(cells) != 4 or not cells[0].isdigit() or cells[0] in result or not cells[1]:
            raise ValueError('Invalid claim-date row')
        end, claim = [datetime.strptime(v, '%B %d, %Y').date() for v in cells[2:]]
        if claim < end:
            raise ValueError('Claim date before game end')
        result[cells[0]] = dict(name=cells[1], end=end, claim=claim, windowMatches=(claim-end).days == 180)
    if not result:
        raise ValueError('Empty claim-date schedule')
    return result


def parse_detail(raw, game, claims, today):
    tree = html.fromstring(raw)
    section = one(tree, '//section[contains(concat(" ",normalize-space(@class)," ")," section-game ")]')
    if text(one(section, './/header//h5')) != game['name']:
        raise ValueError('Detail name mismatch')
    images = section.xpath('.//img/@src')
    if not any(re.search('/' + re.escape(game['id']) + r'_scratched\.(jpg|png)(\?|$)', src) for src in images):
        raise ValueError('Detail image/game identity mismatch')
    badges = section.xpath('.//ul[@class="list-badges"]/li')
    if len(badges) < 2 or 'Top Prize' not in text(badges[0]) or 'Ticket' not in text(badges[1]):
        raise ValueError('Changed prize/price badges')
    for badge, expected in zip(badges, [game['topPrize'], game['cost']]):
        if number(text(one(badge, './/h4')).replace(' ', '')) != expected:
            raise ValueError('Detail price/top mismatch')
    table = one(section, './/table[contains(@class,"prize-chart-table")]')
    if [text(c) for c in table.xpath('./thead/tr/th')] != ['Number of Prizes','Prize Amount','Remaining Prizes','Odds']:
        raise ValueError('Changed detail tier headers')
    tiers = []; unavailable = []; seen = set()
    for row in table.xpath('./tbody/tr'):
        cells = [text(c) for c in row.xpath('./td')]
        if len(cells) != 4:
            raise ValueError('Malformed detail tier')
        original, amount = number(cells[0]), number(cells[1])
        if original <= 0 or amount <= 0 or amount in seen:
            raise ValueError('Duplicate or invalid prize structure')
        seen.add(amount)
        if amount < 25:
            if cells[2] != '*not available':
                raise ValueError('Changed lower-tier availability')
            unavailable.append(amount)
        else:
            remaining = number(cells[2])
            if remaining > original:
                raise ValueError('Remaining exceeds original prizes')
            tiers.append(dict(prizeAmount=amount, original=original, remaining=remaining))
    if {t['prizeAmount']:t['remaining'] for t in tiers} != game['tiers']:
        raise ValueError('Catalog/detail inventory mismatch')
    body = text(one(section, './/*[@id="tab3"]'))
    if 'Prizes are updated once daily. Prizes below $25 are not available.' not in body:
        raise ValueError('Changed inventory cadence/coverage statement')
    launches = re.findall(r'Launch Date\s*:\s*(\d{1,2}/\d{1,2}/\d{4})', body)
    if 'Launch Date' in body and len(launches) != 1:
        raise ValueError('Invalid launch date')
    start = datetime.strptime(launches[0], '%m/%d/%Y').date() if launches else None
    if start and start > today:
        return None
    closing = claims.get(game['id'])
    if closing and closing['name'] != game['name']:
        raise ValueError('Claim schedule identity conflict')
    if closing and closing['end'] < today:
        return None
    if closing and not closing['windowMatches']:
        raise ValueError('Current game has conflicting claim window')
    top = next(t for t in tiers if t['prizeAmount'] == game['topPrize'])
    note = 'Official current Scratch catalog; remaining-prize counts cover prizes $25 or more only and are updated once daily. The source does not publish an inventory verification date. Lower-tier remaining counts are unavailable, not zero. Original prize quantities are a prize structure, not dated claims. Remaining prizes are not winning-ticket totals or verified store stock.'
    if not start:
        note += ' Launch date not published.'
    result = dict(stateName='Idaho', id=game['id'], name=game['name'], cost=game['cost'], topPrize=game['topPrize'], topPrizesRemaining=top['remaining'], originalTopPrizes=top['original'], prizeTiers=tiers, unavailableRemainingPrizeAmounts=sorted(unavailable,reverse=True), sourceUrl=ROOT+game['path'], sourceDate=None, inventoryNote=note)
    if start:
        result['startDate'] = start.isoformat()
    if closing:
        result.update(endDate=closing['end'].isoformat(),lastDayToRedeem=closing['claim'].isoformat())
        result['inventoryNote'] += f' Official game end: {closing["end"]}; last day to claim: {closing["claim"]}.'
    return result


def fetch(url):
    return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3',url],check=True,capture_output=True).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output',type=Path)
    args = parser.parse_args()
    now = datetime.now(ZoneInfo('America/Boise'))
    catalog = parse_catalog(fetch(SOURCE)); claims = parse_claims(fetch(CLAIMS))
    def detail(game):
        return parse_detail(fetch(ROOT+game['path']),game,claims,now.date())
    with ThreadPoolExecutor(max_workers=4) as pool:
        games = [g for g in pool.map(detail,catalog.values()) if g is not None]
    if len(games) < 20:
        raise ValueError('Unexpectedly small verified catalog')
    data = dict(source='Idaho official current Scratch games and detail prize tables',updatedAt=now.isoformat(),catalogs=[dict(state='Idaho',source=SOURCE,sourceDate=None,updateCadence='Source states once daily; checked every six hours. Inventory verification date not published.',coverage='Current listed Scratch games, verified against each detail and claim schedule. Remaining prizes $25 or more only; lower-tier counts unknown. No dated winning-ticket totals or retailer stock/joins.',games=sorted(games,key=lambda g:int(g['id'])))])
    if args.output.exists():
        old=json.loads(args.output.read_text())
        if old.get('catalogs') == data['catalogs']:
            data['updatedAt']=old['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(data,indent=2)+'\n');temp.replace(args.output)
    print(f'Validated {len(games)} Idaho games with {sum(len(g["prizeTiers"]) for g in games)} published inventory tiers')

if __name__ == '__main__':
    main()
