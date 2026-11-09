"""Bounded reviewed printed structures; never actual claims or inventory."""
import copy
import json
from decimal import Decimal, InvalidOperation
from pathlib import Path


def compose(images, spec=None):
    if spec is None:
        spec = json.loads(Path(__file__).with_name('delaware_reviewed_instant_tiers.json').read_text())
    if spec.get('scope') != 'ordered-ticket-prize-structure':
        raise ValueError('Unexpected tier scope')
    if not spec.get('tables'):
        raise ValueError('No reviewed tier tables')
    sources = {item['gameId']: item for item in images}
    if len(sources) != len(images):
        raise ValueError('Duplicate source identity')
    result, seen = [], set()
    for table in spec['tables']:
        gid = table['gameId']
        if gid in seen or gid not in sources:
            raise ValueError('Duplicate or missing tier source')
        seen.add(gid)
        source = sources[gid]
        if table['sourceSha256'] != source['sha256'] or table['sourceUrl'] != source['sourceUrl']:
            raise ValueError('Reviewed tier source changed')
        for key in ('ticketPrice', 'statedTicketsOrdered', 'printedPrizeTotal', 'printedPrizeValue'):
            if type(table[key]) is not int or table[key] <= 0:
                raise ValueError('Invalid printed summary')
        rows, combinations = table['tiers'], set()
        if not rows:
            raise ValueError('Empty tier table')
        for row in rows:
            combination = row['combination']
            if not isinstance(combination, str) or not combination.strip() or combination in combinations:
                raise ValueError('Invalid or duplicate combination')
            combinations.add(combination)
            for key in ('win', 'printedWinners', 'printedPrizeValue'):
                if type(row[key]) is not int or row[key] <= 0:
                    raise ValueError('Invalid tier value')
            try:
                odds = Decimal(row['oddsOneIn'])
            except (InvalidOperation, TypeError, ValueError):
                raise ValueError('Invalid printed odds')
            if not isinstance(row['oddsOneIn'], str) or not odds.is_finite() or odds < 1:
                raise ValueError('Invalid printed odds')
            if row['win'] * row['printedWinners'] != row['printedPrizeValue']:
                raise ValueError('Tier valuation does not reconcile')
        if (sum(r['printedWinners'] for r in rows) != table['printedPrizeTotal'] or
                sum(r['printedPrizeValue'] for r in rows) != table['printedPrizeValue'] or
                table['printedPrizeTotal'] > table['statedTicketsOrdered']):
            raise ValueError('Printed totals do not reconcile')
        item = copy.deepcopy(table)
        item.update(names=source['names'], sourceRetrievedAt=source['retrievedAt'],
                    countMeaning='printed-prizes-in-ordered-ticket-run',
                    actualClaimsAvailable=False, remainingInventoryAvailable=False)
        result.append(item)
    return result
