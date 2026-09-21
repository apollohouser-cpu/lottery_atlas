"""Import NH's public prize inventory joined to its printed game schedule."""
import argparse
from collections import defaultdict
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
import json
from pathlib import Path
import re
import subprocess
import time
import urllib.error
import urllib.request
from lxml import html

SOURCE = 'https://www.nhlottery.com/prizes/prizes-remaining'
SCHEDULE = 'https://www.nhlottery.com/Games/Scratch-Tickets/Current-Scratch-Game-Schedule'
API = 'https://prod.game-data.gambytservices.com/v1/instant-game/prizes-remaining'
# Published prize-page footnotes, verified September 21, 2026.
ANNUITIES = {1000000: (25, 700000), 2000000: (30, 1350000), 3000000: (30, 1750000)}


def integer(value, positive=False):
    if type(value) is not int or value < (1 if positive else 0):
        raise ValueError('Invalid nonnegative integer')
    return value


def money(value, dollar_optional=False):
    if not isinstance(value, str) or not re.fullmatch(r'\$?\d[\d,]*' if dollar_optional else r'\$\d[\d,]*', value):
        raise ValueError('Invalid explicit money')
    return integer(int(value.replace('$', '').replace(',', '')), True)


def date(value):
    if not value:
        return None
    return datetime.strptime(value, '%m/%d/%Y' if len(value.split('/')[-1]) == 4 else '%m/%d/%y').date()


def preloaded(raw):
    root = html.fromstring(raw)
    scripts = [s.text for s in root.xpath('//script') if s.text and 'window.__PRELOADED_STATE__ = ' in s.text]
    if len(scripts) != 1:
        raise ValueError('Missing or ambiguous published state')
    return json.loads(scripts[0].split('window.__PRELOADED_STATE__ = ', 1)[1].strip().rstrip(';'))


def schedule(raw):
    root = html.fromstring(raw)
    tables = root.xpath('//table')
    expected = ['Game Number', 'Price', 'Game Name', 'On Sale', 'Sale End', 'Close Date', 'Expiration Date']
    if len(tables) != 1 or [' '.join(t.text_content().split()) for t in tables[0].xpath('.//tr')[0].xpath('./th|./td')] != expected:
        raise ValueError('Changed schedule headers')
    result = {}
    for row in tables[0].xpath('.//tr')[1:]:
        if row.xpath('./td[contains(@class,"table__cell--stacked-header")]'):
            continue  # Duplicate mobile presentation, not additional games.
        cells = [' '.join(t.text_content().split()) for t in row.xpath('./td')]
        if len(cells) != 7 or not cells[0].isdigit() or cells[0] in result:
            raise ValueError('Invalid or duplicate schedule row')
        result[cells[0]] = cells
    if not result:
        raise ValueError('Empty schedule')
    return result


def parse_catalog(state, inventory, rows, today):
    stamp = inventory['lastUpdated']
    source_time = datetime.fromisoformat(stamp.replace('Z', '+00:00'))
    if source_time.tzinfo is None:
        raise ValueError('Invalid source timestamp')
    source_time = source_time.astimezone(timezone.utc)
    cms = state['cmsGames']['gamesByDataServiceId']
    metadata = state['instantGames']['instantGamesByDataServiceId']
    grouped = defaultdict(list)
    tier_ids = set()
    for t in inventory['prizesRemaining']:
        tid = t['id']
        if not isinstance(tid, str) or not tid or tid in tier_ids:
            raise ValueError('Invalid or duplicate tier ID')
        tier_ids.add(tid)
        amount = integer(t['prizeAmountInDollars'], True)
        original = integer(t['startingCount'], True)
        remaining = integer(t['remainingCount'])
        if remaining > original:
            raise ValueError('Remaining count exceeds original')
        grouped[t['instantGameId']].append(t)
    games, missing, ids = [], [], set()
    for uid, tiers in grouped.items():
        c, g = cms[uid], metadata[uid]
        gid = g['gameId']
        if not isinstance(gid, str) or not gid.isdigit() or gid in ids:
            raise ValueError('Invalid or duplicate printed identity')
        ids.add(gid)
        if c['type'] != 'scratch' or g['salesChannel'] != 'RETAIL' or c['configuration']['dataServices']['gameDataServiceId'] != uid:
            raise ValueError('Inventory is not a joined retail Scratch game')
        cents = integer(c['price']['priceInCents'], True)
        if cents % 100 or money(c['price']['priceFormatted']) * 100 != cents or g['ticketCostOptionsInCents'] != [cents] or any(t['ticketCostOptionsInCents'] != [cents] for t in tiers):
            raise ValueError('Conflicting ticket prices')
        label = c['topPrizeDisplay']
        top = money(label.rstrip('*'), dollar_optional=True)
        if max(t['prizeAmountInDollars'] for t in tiers) != top:
            raise ValueError('Conflicting top prizes')
        if gid not in rows:
            missing.append(gid)
            continue
        row = rows[gid]
        if money(row[1]) * 100 != cents:
            raise ValueError('Schedule price disagreement')
        start, end, close, expires = [date(v) for v in row[3:]]
        cms_start = date(c['startDate'])
        if start is None or cms_start is None or (end and close and close < end) or (close and expires and expires < close):
            raise ValueError('Invalid schedule dates')
        if max(start, cms_start) > today or (expires and expires < today):
            continue
        name = c['name']
        if not isinstance(name, str) or not name.strip():
            raise ValueError('Missing name')
        note = f'Prize inventory updated {source_time.isoformat()}; publication cadence unconfirmed. Remaining prizes are not dated winning-ticket totals or verified store stock. Tickets may be sold after top prizes are claimed.'
        game = dict(stateName='New Hampshire', id=gid, name=name, cost=cents // 100, topPrize=top,
                    topPrizesRemaining=sum(t['remainingCount'] for t in tiers if t['prizeAmountInDollars'] == top),
                    sourceUrl=SOURCE, sourceDate=source_time.date().isoformat(), inventoryTimestamp=source_time.isoformat(),
                    prizeTiers=[dict(prizeAmount=t['prizeAmountInDollars'], prizeLabel=t.get('prizeDescription'), original=t['startingCount'], remaining=t['remainingCount']) for t in sorted(tiers, key=lambda t: t['id'])])
        if label.endswith('*'):
            if top not in ANNUITIES:
                raise ValueError('Unrecognized annuity prize')
            years, cash = ANNUITIES[top]
            game['topPrize'] = cash
            game['topPrizeLabel'] = f'${top:,} over {years} years or ${cash:,} cash before taxes'
            note += ' Top-tier counts refer to the advertised annuity/cash-choice prize.'
        if start == cms_start:
            game['startDate'] = start.isoformat()
        else:
            game['scheduleOnSaleDate'] = start.isoformat()
            game['cmsStartDate'] = cms_start.isoformat()
            note += f' Source dates disagree: schedule on-sale {start}; CMS start {cms_start}. No normalized start date assigned.'
        for key, value, caption in [('saleEndDate', end, 'Sale end'), ('closeDate', close, 'Close date'), ('lastDayToRedeem', expires, 'Prize expiration')]:
            if value:
                game[key] = value.isoformat()
                note += f' {caption}: {value}.'
        game['inventoryNote'] = note
        games.append(game)
    if not games:
        raise ValueError('No eligible matched games')
    missing.sort(key=int)
    if missing:
        for game in games:
            game['inventoryNote'] += ' Inventory games omitted because no schedule record was found: ' + ', '.join(missing) + '.'
    return dict(state='New Hampshire', source=SOURCE, sourceDate=source_time.date().isoformat(), inventoryTimestamp=source_time.isoformat(),
                updateCadence='Publication cadence unconfirmed; checked every six hours.',
                coverage='Public retail Scratch prize inventory matched to CMS and printed schedule. Missing schedule records excluded. Not all-tier dated claims or retailer-linked activity.',
                excludedMissingScheduleIds=missing, games=sorted(games, key=lambda g: int(g['id'])))


def fetch(url, headers=None):
    for attempt in range(4):
        try:
            if not headers:
                return subprocess.run(['curl', '-fsSL', '--max-time', '30', '--retry', '3', url], capture_output=True, check=True).stdout
            with urllib.request.urlopen(urllib.request.Request(url, headers=headers or {}), timeout=30) as response:
                return response.read()
        except subprocess.CalledProcessError as error:
            if error.returncode not in {6, 7} or attempt == 3:
                raise
            time.sleep(attempt + 1)
        except (urllib.error.URLError, TimeoutError) as error:
            if isinstance(error, urllib.error.HTTPError) and error.code not in {408, 429, 500, 502, 503, 504}:
                raise
            if attempt == 3:
                raise
            time.sleep(attempt + 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    raw = fetch(SOURCE)
    root = html.fromstring(raw)
    # Read the public configuration from the bundle actually referenced by the official page.
    bundles = [u for u in root.xpath('//script[@src]/@src') if re.fullmatch(r'https://[a-z0-9]+\.cloudfront\.net/index\.js', u)]
    if len(bundles) != 1:
        raise ValueError('Missing public frontend bundle')
    bundle = fetch(bundles[0]).decode()
    for amount, (years, cash) in ANNUITIES.items():
        if f'${amount:,} PRIZE PAID AS ANNUITY OVER {years} YRS, OR AS CASH OF ${cash:,} BEFORE TAXES' not in bundle:
            raise ValueError('Changed published annuity terms')
    keys = re.findall(r'GAME_DATA_API_KEY:"([^"]+)"', bundle)
    if len(keys) != 1 or 'GAME_DATA_BASE_URL:"https://prod.game-data.gambytservices.com"' not in bundle:
        raise ValueError('Changed public API configuration')
    inventory = json.loads(fetch(API, {'X-API-Key': keys[0], 'X-Client-ID': 'nh-portal-server'}))
    now = datetime.now(timezone.utc)
    if datetime.fromisoformat(inventory['lastUpdated'].replace('Z', '+00:00')) > now + timedelta(minutes=5):
        raise ValueError('Future inventory timestamp')
    catalog = parse_catalog(preloaded(raw), inventory, schedule(fetch(SCHEDULE)), now.astimezone(ZoneInfo('America/New_York')).date())
    if len(catalog['games']) < 30:
        raise ValueError('Unexpectedly small matched catalog')
    result = dict(source='New Hampshire official retail Scratch inventory and schedule', updatedAt=now.isoformat(), catalogs=[catalog])
    if args.output.exists():
        old = json.loads(args.output.read_text())
        if old.get('catalogs') == result['catalogs']:
            result['updatedAt'] = old['updatedAt']
    temp = args.output.with_suffix('.tmp')
    temp.write_text(json.dumps(result, indent=2) + '\n')
    temp.replace(args.output)
    print(f'Validated {len(catalog["games"])} New Hampshire games; omitted missing schedule IDs: {catalog["excludedMissingScheduleIds"]}')


if __name__ == '__main__':
    main()
