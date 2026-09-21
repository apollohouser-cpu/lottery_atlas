"""Import Maryland's public finder, preserving dated inventory and prize categories."""
import argparse
from datetime import date, datetime
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import urlencode
from zoneinfo import ZoneInfo
from lxml import html

SOURCE = 'https://www.mdlottery.com/games/scratch-offs/'
ENDPOINT = 'https://www.mdlottery.com/wp-admin/admin-ajax.php?' + urlencode({
    'action': 'jquery_shortcode', 'shortcode': 'scratch_offs',
    'atts': '{"null":"null"}',
})


def plain(node):
    return ' '.join(node.text_content().split())


def field(node, name):
    values = node.xpath('.//*[contains(concat(" ", normalize-space(@class), " "), " ' + name + ' ")]')
    if len(values) != 1:
        raise ValueError(f'Missing or ambiguous {name}')
    return plain(values[0])


def integer(value):
    if not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)', value):
        raise ValueError('Invalid inventory integer')
    return int(value.replace(',', ''))


def money(value):
    match = re.fullmatch(r'\$(\d[\d,]*)', value)
    if not match:
        raise ValueError('Invalid cash amount')
    return integer(match[1])


def parse_catalog(raw, today):
    tree = html.fromstring(raw.decode('utf-8') if isinstance(raw, bytes) else raw)
    cards = tree.xpath('//*[@id and starts-with(@id,"ticket_")]')
    if not cards:
        raise ValueError('Missing ticket catalog')
    seen = set()
    games = []
    for card in cards:
        gid = card.get('id').removeprefix('ticket_')
        if not gid.isdigit() or gid in seen or field(card, 'gamenumber') != 'Game #' + gid:
            raise ValueError('Duplicate or inconsistent printed identity')
        seen.add(gid)
        deadlines = card.xpath('.//*[contains(concat(" ", normalize-space(@class), " "), " lastclaimdate ")]')
        if len(deadlines) > 1:
            raise ValueError('Ambiguous claim deadline')
        deadline = datetime.strptime(plain(deadlines[0]), '%m/%d/%Y').date() if deadlines else None
        if deadline and deadline < today:
            continue
        start = datetime.strptime(field(card, 'launchdate'), '%m/%d/%Y').date()
        if start > today:
            continue
        stamps = re.findall(r'Records Last Updated: (\d{2}/\d{2}/\d{4})', plain(card))
        if len(stamps) != 1:
            raise ValueError('Missing or ambiguous inventory date')
        stamp = datetime.strptime(stamps[0], '%m/%d/%Y').date()
        if stamp > today:
            raise ValueError('Future inventory date')
        tables = card.xpath('.//table')
        if len(tables) != 1 or [plain(x) for x in tables[0].xpath('./thead/tr/th')] != ['Prize Amount', 'Start', 'Remaining*']:
            raise ValueError('Changed tier schema')
        tiers = []
        labels = set()
        for row in tables[0].xpath('./tbody/tr'):
            cells = [plain(x) for x in row.xpath('./td')]
            if len(cells) != 3:
                raise ValueError('Incomplete tier')
            label, total, remaining = cells
            if label in labels:
                raise ValueError('Duplicate tier label')
            labels.add(label)
            total, remaining = integer(total), integer(remaining)
            if remaining > total:
                raise ValueError('Remaining exceeds original inventory')
            tier = dict(prizeLabel=label, total=total, remaining=remaining)
            if label == 'BIG SPIN':
                tier['prizeCategory'] = 'spin opportunity'
            elif re.fullmatch(r'\$[\d,]+', label):
                tier.update(prizeAmount=money(label), prizeCategory='cash')
            else:
                spin = re.fullmatch(r'\$?(\d[\d,]*)(?:\.00)? \((Digital Spin|SPIN)\)', label)
                if not spin:
                    raise ValueError('Unknown prize format')
                tier.update(prizeAmount=integer(spin[1]), prizeCategory='digital spin')
            tiers.append(tier)
        top_label = field(card, 'topprize')
        top = [x for x in tiers if x['prizeLabel'] == top_label]
        if len(top) != 1 or top[0]['remaining'] != integer(field(card, 'topremaining')):
            raise ValueError('Card and top tier disagree')
        if sum(x['remaining'] for x in tiers) != integer(field(card, 'allremaining')):
            raise ValueError('Tier sum and card disagree')
        cash = [x['prizeAmount'] for x in tiers if x['prizeCategory'] == 'cash']
        if not cash or (top_label != 'BIG SPIN' and money(top_label) != max(cash)):
            raise ValueError('Invalid cash top prize')
        price = money(field(card, 'price'))
        name = field(card, 'name')
        if price <= 0 or not name:
            raise ValueError('Missing name or price')
        note = f'Inventory as of {stamp.isoformat()}; updated daily by the lottery. Remaining prizes may include sold tickets not yet cashed. Not dated winning-ticket counts or verified store stock.'
        if top_label == 'BIG SPIN':
            note += f' BIG SPIN is a spin opportunity; amount filters use the highest fixed cash prize, ${max(cash):,}.'
        if deadline:
            note += f' Last day to claim: {deadline.isoformat()}.'
        game = dict(stateName='Maryland', id=gid, name=name, cost=price,
                    topPrize=max(cash), topPrizesRemaining=top[0]['remaining'],
                    sourceUrl=SOURCE, sourceDate=stamp.isoformat(),
                    startDate=start.isoformat(), prizeTiers=tiers, inventoryNote=note)
        if top_label == 'BIG SPIN':
            game['topPrizeLabel'] = top_label
        if deadline:
            game['lastDayToRedeem'] = deadline.isoformat()
        games.append(game)
    if not games:
        raise ValueError('No eligible games')
    dates = sorted({g['sourceDate'] for g in games})
    return dict(state='Maryland', source=SOURCE,
                sourceDate=dates[0] if len(dates) == 1 else None,
                updateCadence='Agency confirms daily inventory updates; checked every six hours.',
                coverage='Published finder games launched and not past their last claim date. Cumulative prize inventory only; not dated claims or retailer-linked activity. Each game retains its inventory date.',
                games=sorted(games, key=lambda g: int(g['id'])))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    now = datetime.now(ZoneInfo('America/New_York'))
    raw = subprocess.run(['curl', '-fsSL', '--max-time', '30', '--retry', '3', ENDPOINT], capture_output=True, check=True).stdout
    catalog = parse_catalog(raw, now.date())
    if len(catalog['games']) < 40:
        raise ValueError('Unexpectedly small catalog')
    result = dict(source='Maryland official dated Scratch-Off inventory', updatedAt=now.isoformat(), catalogs=[catalog])
    if args.output.exists():
        old = json.loads(args.output.read_text())
        if old.get('catalogs') == result['catalogs']:
            result['updatedAt'] = old['updatedAt']
    temp = args.output.with_suffix('.tmp')
    temp.write_text(json.dumps(result, indent=2) + '\n')
    temp.replace(args.output)
    print(f"Validated {len(catalog['games'])} eligible Maryland games")


if __name__ == '__main__':
    main()
