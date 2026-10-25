"""Strict Oklahoma Fast Play source parsing; no standalone publication.

Only launched, no-end-date progressive games are currently supported. JACKPOT
is categorical; the separately advertised estimate is not a fixed tier prize.
"""
from datetime import datetime
import re
from zoneinfo import ZoneInfo

from import_oklahoma_scratch_catalog import embedded, integer

SOURCE = 'https://oklottery.com/games/fast-play'


def timestamp(value):
    if not isinstance(value, str):
        raise ValueError('Missing timestamp')
    try:
        result = datetime.fromisoformat(value)
    except ValueError as error:
        raise ValueError('Invalid timestamp') from error
    if result.tzinfo is None:
        raise ValueError('Missing timestamp timezone')
    return result


def parse_listing(raw, today):
    games = embedded(raw, 'fastPlayGames')
    if not isinstance(games, list) or not games:
        raise ValueError('Missing Fast Play listing')
    selected, ids, slugs = [], set(), set()
    for game in games:
        if not isinstance(game, dict):
            raise ValueError('Invalid game')
        gid = integer(game.get('gameId'), True)
        slug = game.get('slug')
        match = re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', slug or '')
        if not match or gid in ids or slug in slugs:
            raise ValueError('Invalid or duplicate game identity')
        ids.add(gid); slugs.add(slug)
        if not isinstance(game.get('title'), str) or not game['title'].strip():
            raise ValueError('Missing game title')
        integer(game.get('ticketPrice'), True)
        integer(game.get('topPrize'))
        if type(game.get('progressive')) is not bool or 'endDate' not in game:
            raise ValueError('Missing game status')
        start = timestamp(game.get('startDate'))
        if game['endDate'] is not None:
            if timestamp(game['endDate']) < start:
                raise ValueError('End before launch')
            continue
        if start.astimezone(ZoneInfo('America/Chicago')).date() > today:
            continue
        if game['progressive'] is not True:
            raise ValueError('New active nonprogressive contract requires review')
        selected.append(game)
    if not selected:
        raise ValueError('No eligible Fast Play games')
    return selected, len(games)


def parse_detail(raw, game):
    detail = embedded(raw, 'cms')
    if not isinstance(detail, dict):
        raise ValueError('Invalid detail')
    for key in ('gameId', 'slug', 'title', 'ticketPrice', 'startDate', 'endDate', 'progressive'):
        if key not in detail or detail[key] != game[key] or type(detail[key]) is not type(game[key]):
            raise ValueError('Listing/detail mismatch: ' + key)
    if detail['endDate'] is not None or detail['progressive'] is not True:
        raise ValueError('Ineligible detail')
    printed = detail.get('gameNumber')
    if not isinstance(printed, str) or not re.fullmatch(r'[1-9][0-9]*', printed):
        raise ValueError('Missing printed game identity')
    prefix = re.match(r'([0-9]+)-', game['slug'])
    if prefix and prefix[1] != printed:
        raise ValueError('Printed game identity mismatch')
    estimate = integer(detail.get('topPrize'))
    tickets = integer(detail.get('totalTickets'), True)
    if 'prizeDetails' not in detail:
        raise ValueError('Missing prize structure')
    groups = detail['prizeDetails']
    tiers, seen = [], set()
    if groups is not None:
        if not isinstance(groups, list) or len(groups) != 1 or not isinstance(groups[0], dict):
            raise ValueError('Ambiguous prize structure')
        rows = groups[0].get('matches')
        if not isinstance(rows, list) or not rows:
            raise ValueError('Missing prize rows')
        for row in rows:
            if not isinstance(row, dict):
                raise ValueError('Invalid prize row')
            label = row.get('prize')
            amount = None
            if label != 'JACKPOT':
                if not isinstance(label, str) or not re.fullmatch(r'\$\$(?:\d+|\d{1,3}(?:,\d{3})+)', label):
                    raise ValueError('Unsupported prize label')
                amount = int(label[2:].replace(',', ''))
                integer(amount, True)
            identity = 'JACKPOT' if amount is None else amount
            if identity in seen:
                raise ValueError('Duplicate prize tier')
            seen.add(identity)
            remaining = integer(row.get('remainingPrizes'))
            total = integer(row.get('totalPrizes'))
            if remaining > total:
                raise ValueError('Impossible remaining inventory')
            tiers.append(dict(prizeLabel=label, prizeAmount=amount,
                              remainingPrizes=remaining, totalPrizes=total))
        if 'JACKPOT' not in seen:
            raise ValueError('Missing categorical jackpot tier')
    return dict(id=printed, internalGameId=game['gameId'], name=game['title'],
                cost=game['ticketPrice'], sourceUrl=SOURCE+'/'+game['slug'],
                startDate=game['startDate'], totalTickets=tickets,
                progressiveEstimate=estimate if estimate > 0 else None,
                prizeTiers=tiers, inventoryStatus='available' if tiers else 'unavailable',
                sourceDate=None,
                inventoryNote='No-end-date progressive Fast Play subset. JACKPOT is categorical; '
                'the separate estimate is variable. Remaining and original prizes are not '
                'dated claims or store stock. Official inventory timestamp/cadence unconfirmed.')
