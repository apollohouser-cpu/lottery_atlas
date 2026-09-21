"""Import Connecticut detail-verified Scratch games; exclude disputed cash values."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html

SOURCE = 'https://www.ctlottery.org/games/scratch-games/all'
EXCLUDED = {1725: 'Catalog cash value conflicts with the detail rules; excluded pending clarification.'}


def plain(node):
    return ' '.join(' '.join(node.itertext()).split())


def integer(value):
    if isinstance(value, int) and not isinstance(value, bool) and value >= 0:
        return value
    if isinstance(value, str) and re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)', value):
        return int(value.replace(',', ''))
    raise ValueError('Invalid nonnegative integer')


def listing(raw):
    tree = html.fromstring(raw.decode('utf-8') if isinstance(raw, bytes) else raw)
    chunks = []
    for script in tree.xpath('//script/text()'):
        match = re.fullmatch(r'self\.__next_f\.push\((\[.*\])\)', script, re.S)
        if match:
            value = json.loads(match[1])
            if len(value) == 2 and value[0] == 1 and isinstance(value[1], str):
                chunks.append(value[1])
    text = ''.join(chunks)
    starts = list(re.finditer(r'"games":(?=\[\{"gameNo":)', text))
    if len(starts) != 1:
        raise ValueError('Missing or ambiguous complete catalog')
    games, _ = json.JSONDecoder().raw_decode(text[starts[0].end():])
    seen = set()
    for game in games:
        gid = integer(game['gameNo'])
        if gid in seen or gid == 0 or game['status'] not in {'new', 'active', 'ended'}:
            raise ValueError('Duplicate identity or unknown status')
        seen.add(gid)
        if integer(game['ticketCostRaw']) == 0 or integer(game['topPrizeRaw']) == 0:
            raise ValueError('Nonpositive price or cash value')
        if integer(game['topPrizesRemaining']) > integer(game['totalTopPrizes']):
            raise ValueError('Invalid top inventory')
        for field in ['startDate', 'stopDate', 'endValDate']:
            date.fromisoformat(game[field])
    return games


def displayed_date(value):
    value = value.strip()
    if value == 'TBD':
        return None
    return datetime.strptime(value.replace('.', '').replace('Sept ', 'Sep '), '%b %d, %Y').date()


def detail(raw, game, today):
    gid = integer(game['gameNo'])
    if gid in EXCLUDED:
        return None
    tree = html.fromstring(raw.decode('utf-8') if isinstance(raw, bytes) else raw)
    for node in tree.xpath('//script|//style'):
        node.drop_tree()
    text = plain(tree)
    match = re.search(r'Game #\s*(\d+)\s+(Active|Ended)\s+Top Prize (.*?) Price \$(\d+) Overall Odds', text)
    if not match or integer(match[1]) != gid or integer(match[4]) != game['ticketCostRaw']:
        raise ValueError('Detail identity or price mismatch')
    label = (game.get('displayTopPrize') or game['topPrize']).replace('$$', '$')
    if match[3] != label or (match[2] == 'Ended') != (game['status'] == 'ended'):
        raise ValueError('Display prize or status mismatch')
    dates = re.search(r'Game Start (.*?) Game End (.*?) Last Day to Claim (.*?) Total Tickets', text)
    if not dates:
        raise ValueError('Missing displayed dates')
    start, end, claim = map(displayed_date, dates.groups())
    expected = [date.fromisoformat(game['startDate'])] + [None if game[k].startswith('2099-') else date.fromisoformat(game[k]) for k in ['stopDate', 'endValDate']]
    if [start, end, claim] != expected or (end and claim and claim < end):
        raise ValueError('Listing/detail date mismatch')
    if start > today or (claim and claim < today):
        return None
    if game['status'] == 'ended' and (end is None or end > today):
        raise ValueError('Ended status lacks valid end date')
    stamps = re.findall(r'As of ([A-Z][a-z]+ \d{1,2}, \d{4})', text)
    if len(stamps) != 1:
        raise ValueError('Missing or ambiguous inventory date')
    stamp = datetime.strptime(stamps[0], '%B %d, %Y').date()
    if stamp > today:
        raise ValueError('Future inventory date')
    tables = tree.xpath('//table[@class="scratch-prizes-table"]')
    if len(tables) != 1 or [plain(x) for x in tables[0].xpath('./thead/tr/th')] != ['Prize Amount', 'Total Prizes', 'Unclaimed Prizes']:
        raise ValueError('Changed prize table schema')
    tiers = []
    seen = set()
    for row in tables[0].xpath('./tbody/tr'):
        cells = [plain(x) for x in row.xpath('./td')]
        if len(cells) != 3 or cells[0] in seen:
            raise ValueError('Incomplete or duplicate tier')
        prize, total, remaining = cells
        seen.add(prize)
        total, remaining = integer(total), integer(remaining)
        if remaining > total or not re.fullmatch(r'\$[\d,]+', prize):
            raise ValueError('Invalid inventory or unsupported prize label')
        tiers.append(dict(prizeLabel=prize, prizeAmount=integer(prize[1:]), total=total, remaining=remaining))
    top = [t for t in tiers if t['prizeLabel'] == label]
    if len(top) != 1 or top[0]['total'] != game['totalTopPrizes']:
        raise ValueError('Original top-tier mismatch')
    # Detail inventory has its own date; do not mix it with listing counts.
    cash = integer(game['topPrizeRaw'])
    if game.get('displayTopPrize'):
        rules = text[text.index('How to Play'):text.index('Prizes Remaining')]
        options = re.findall(r'(?:gross cash option(?: payment)? of|cash option(?: payment)? of) \$([\d,]+)', rules)
        if len(options) != 1 or integer(options[0]) != cash:
            raise ValueError('Unverified annuity cash option')
        top[0]['prizeCategory'] = 'annuity'
    elif max(t['prizeAmount'] for t in tiers) != cash:
        raise ValueError('Cash top-prize mismatch')
    name = plain(html.fromstring(game['displayNameHtml'])) if game.get('displayNameHtml') else game['gameName'].replace('$$', '$').strip()
    if not name:
        raise ValueError('Missing game name')
    note = f'Inventory as of {stamp.isoformat()}. Cumulative unclaimed prizes, not dated winning-ticket counts or verified store stock. Publication cadence unconfirmed. Catalog excludes game 1725 due to conflicting cash values.'
    if game['status'] == 'ended':
        note += f' Sales ended {end.isoformat()}; claimable through {claim.isoformat()}.' if claim else f' Sales ended {end.isoformat()}; claim deadline unknown.'
    elif claim:
        note += f' Last day to claim: {claim.isoformat()}.'
    if game.get('displayTopPrize'):
        note += f' Advertised prize is an annuity; amount filters use the verified ${cash:,} cash option.'
    result = dict(stateName='Connecticut', id=str(gid), name=name, cost=game['ticketCostRaw'], topPrize=cash,
                  topPrizesRemaining=top[0]['remaining'], sourceUrl=f'https://www.ctlottery.org/games/scratch-games/{gid}',
                  sourceDate=stamp.isoformat(), startDate=start.isoformat(), status=game['status'], prizeTiers=tiers, inventoryNote=note)
    if end:
        result['endDate'] = end.isoformat()
    if claim:
        result['lastDayToRedeem'] = claim.isoformat()
    if game.get('displayTopPrize'):
        result['topPrizeLabel'] = label + ' annuity'
    return result


def fetch(url):
    return subprocess.run(['curl', '-fsSL', '--max-time', '30', '--retry', '3', url], capture_output=True, check=True).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    now = datetime.now(ZoneInfo('America/New_York'))
    candidates = [g for g in listing(fetch(SOURCE)) if g['gameNo'] not in EXCLUDED]
    with ThreadPoolExecutor(max_workers=2) as pool:
        parsed = list(pool.map(lambda g: detail(fetch(f'https://www.ctlottery.org/games/scratch-games/{g["gameNo"]}'), g, now.date()), candidates))
    games = sorted([g for g in parsed if g], key=lambda g: int(g['id']))
    if len(games) < 30:
        raise ValueError('Unexpectedly small eligible catalog')
    dates = sorted({g['sourceDate'] for g in games})
    catalog = dict(state='Connecticut', source=SOURCE, sourceDate=dates[0] if len(dates) == 1 else None,
                   coverage='Published unexpired games, including clearly labeled ended but claimable games. Game 1725 excluded because its cash values conflict. Inventory is not dated claims or retailer-linked activity.',
                   excludedGames=[dict(id=str(k), reason=v) for k, v in EXCLUDED.items()],
                   updateCadence='Checked every six hours; source publication cadence unconfirmed.', games=games)
    result = dict(source='Connecticut official detail-verified Scratch inventory', updatedAt=now.isoformat(), catalogs=[catalog])
    if args.output.exists():
        old = json.loads(args.output.read_text())
        if old.get('catalogs') == result['catalogs']:
            result['updatedAt'] = old['updatedAt']
    temp = args.output.with_suffix('.tmp')
    temp.write_text(json.dumps(result, indent=2) + '\n')
    temp.replace(args.output)
    print(f'Validated {len(games)} eligible Connecticut games')


if __name__ == '__main__':
    main()
