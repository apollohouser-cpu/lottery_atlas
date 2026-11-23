"""Bind an already reviewed Scratch catalog to a CT coverage candidate."""
import hashlib
import json
from datetime import date
from urllib.parse import urlsplit


def package(raw, reviewed_sha256, observed_date):
    if hashlib.sha256(raw).hexdigest() != reviewed_sha256:
        raise ValueError('Unreviewed Scratch catalog bytes')
    payload = json.loads(raw)
    catalogs = payload.get('catalogs', [])
    if len(catalogs) != 1 or catalogs[0].get('state') != 'Connecticut':
        raise ValueError('Not a single Connecticut catalog')
    catalog = catalogs[0]
    if not any(e.get('id') == '1725' and e.get('reason') for e in catalog.get('excludedGames', [])):
        raise ValueError('Missing disputed-game exclusion')
    if not catalog.get('coverage') or not catalog.get('games'):
        raise ValueError('Missing coverage or games')
    seen = set()
    for game in catalog['games']:
        gid = game.get('id')
        if not isinstance(gid, str) or not gid.isdigit() or gid in seen or gid == '1725':
            raise ValueError('Invalid, duplicate or excluded game')
        seen.add(gid)
        if game.get('stateName') != 'Connecticut' or game.get('status') not in {'active', 'new', 'ended'}:
            raise ValueError('Invalid state or status')
        source_date = date.fromisoformat(game['sourceDate'])
        if source_date > observed_date:
            raise ValueError('Future inventory date')
        for field in ['startDate', 'endDate', 'lastDayToRedeem']:
            if field in game:
                date.fromisoformat(game[field])
        if game['status'] == 'ended' and not game.get('endDate'):
            raise ValueError('Ended game missing sales-end date')
        url = urlsplit(game['sourceUrl'])
        if (url.scheme != 'https' or url.netloc not in {'ctlottery.com', 'www.ctlottery.org'} or
                url.path != '/games/scratch-games/' + gid or url.query or url.fragment):
            raise ValueError('Mismatched game source')
        for field in ['cost', 'topPrize']:
            if type(game.get(field)) is not int or game[field] <= 0:
                raise ValueError('Invalid price')
        if not game.get('inventoryNote') or not game.get('name') or not game.get('prizeTiers'):
            raise ValueError('Missing detail content')
        for tier in game['prizeTiers']:
            if (not tier.get('prizeLabel') or
                    any(type(tier.get(k)) is not int or tier[k] < 0 for k in ['total', 'remaining']) or
                    tier['remaining'] > tier['total']):
                raise ValueError('Invalid prize inventory')
            if tier.get('prizeCategory') == 'annuity' and not game.get('topPrizeLabel'):
                raise ValueError('Missing annuity label')
    # Return original fields and dates unchanged, never restamp retrieval as source.
    return catalog
