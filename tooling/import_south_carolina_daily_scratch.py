"""Import official one-day SC Scratch claims, never remaining inventory."""
import hashlib
import html
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.request import urlopen
from zoneinfo import ZoneInfo

SOURCE = 'https://www.sceducationlottery.com/Games/DailyInstantWinners'


def text(value):
    return ' '.join(html.unescape(re.sub(r'<[^>]+>', ' ', value)).split())


def parse(raw):
    heading = re.search(r'<h1[^>]*>Daily Scratch-Off Winners for (.*?)</h1>', raw)
    updated = re.search(r'Last Update on\s*<strong[^>]*>(.*?)</strong>', raw)
    if not heading or not updated:
        raise ValueError('Missing source dates')
    day = datetime.strptime(text(heading[1]), '%B %d, %Y').date()
    stamp = datetime.strptime(text(updated[1]), '%m/%d/%Y %I:%M:%S %p').replace(tzinfo=ZoneInfo('America/New_York'))
    if day >= stamp.date():
        raise ValueError('Claim day must precede publication day')
    blocks = re.findall(r'<strong>Daily Scratch-Off Winners for (.*?)</strong>(.*?)<strong>End of Daily Scratch-Offs Winners for (.*?)</strong>', raw, re.S)
    if not blocks:
        raise ValueError('No daily claim tables')
    games = {}
    for name_raw, body, end_raw in blocks:
        name = text(name_raw)
        if not name or name != text(end_raw):
            raise ValueError('Mismatched table boundaries')
        rows = re.findall(r'<tr[^>]*>(.*?)</tr>', body, re.S)
        tiers = {}
        for row in rows:
            cells = re.findall(r'<td\s+data-th="([^"]+)"[^>]*>(.*?)</td>', row, re.S)
            if not cells:
                continue
            if [c[0] for c in cells] != ['Prize Amount', 'Number of Winners', 'Total Prizes']:
                raise ValueError('Unexpected tier columns')
            values = [text(c[1]).replace('$', '').replace(',', '') for c in cells]
            if any(not re.fullmatch(r'\d+', v) for v in values):
                raise ValueError('Non-integer tier')
            amount, count, payout = map(int, values)
            if amount < 1 or amount in tiers or amount * count != payout:
                raise ValueError('Duplicate tier or payout mismatch')
            tiers[amount] = count
        if not tiers:
            raise ValueError('Empty game')
        game = games.setdefault(name, {'id': 'sc-daily-' + hashlib.sha256(name.encode()).hexdigest()[:16], 'name': name, 'groupedOfficialEntries': 0, 'tiers': {}})
        game['groupedOfficialEntries'] += 1
        for amount, count in tiers.items():
            game['tiers'][amount] = game['tiers'].get(amount, 0) + count
    if len(blocks) != raw.count('End of Daily Scratch-Offs Winners for '):
        raise ValueError('Unparsed game table')
    result = []
    for game in games.values():
        tiers = game.pop('tiers')
        game['prizeTiers'] = [{'amount': amount, 'claimedYesterday': count} for amount, count in sorted(tiers.items())]
        result.append(game)
    return {'state': 'SC', 'source': SOURCE, 'updatedAt': stamp.isoformat(), 'claimDate': day.isoformat(),
            'coverage': 'One source-reported day of statewide Scratch claims by prize tier; not remaining inventory or retailer activity. Duplicate titles are grouped, not deduplicated.',
            'games': result}


def main():
    output = Path(sys.argv[1])
    with urlopen(SOURCE, timeout=45) as response:
        result = parse(response.read().decode('utf-8'))
    if output.exists():
        previous = json.loads(output.read_text())
        if result['claimDate'] < previous['claimDate']:
            raise ValueError('Source day regressed; retaining prior snapshot')
    temporary = output.with_suffix('.tmp')
    temporary.write_text(json.dumps(result, indent=2) + '\n')
    temporary.replace(output)
    print(f"Imported {len(result['games'])} grouped titles for {result['claimDate']}")


if __name__ == '__main__':
    main()
