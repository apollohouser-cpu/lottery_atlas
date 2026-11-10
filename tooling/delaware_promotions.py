"""Bounded retained coming-soon and second-chance observations; no enrollment."""
from datetime import datetime
import hashlib
from html.parser import HTMLParser
import json

SOURCES = {
    'Coming-Soon': '2104654bfb1b10d4c318807db9df32374b0e457ef4e531848d1f2e79512aabd9',
    'Second-Chance-Drawing': 'b1df72f183d2ee13f10436fbe683d668307d32ecca4498fcfeaa0c947279d407',
}


class ComingSoon(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.games = {}

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'section' and attrs.get('class') == 'coming-soon-game':
            self.active = True
        if not self.active or 'data-gamename' not in attrs:
            return
        gid = attrs['data-gamenumber']
        if not gid.isdigit():
            raise ValueError('Invalid coming-soon identity')
        row = dict(gameId=gid, name=attrs['data-gamename'],
                   ticketPrice=int(attrs['data-amount']),
                   advertisedTopPrize=int(attrs['data-topprize'].replace(',', '')),
                   instructions=attrs['data-gamedescription'])
        if row['ticketPrice'] <= 0 or row['advertisedTopPrize'] <= 0 or not row['name']:
            raise ValueError('Invalid coming-soon values')
        if gid in self.games and self.games[gid] != row:
            raise ValueError('Conflicting shared coming-soon identity')
        self.games[gid] = row

    def handle_endtag(self, tag):
        if tag == 'section':
            self.active = False


def build(root):
    manifest = json.loads((root / 'rules-history-manifest.json').read_text())
    evidence, contents = {}, {}
    for suffix, digest in SOURCES.items():
        url = 'https://www.delottery.com/Instant-Games/' + suffix
        matches = [x for x in manifest if x['url'] == url]
        if len(matches) != 1:
            raise ValueError('Missing or duplicate promotion source')
        record = matches[0]
        raw = (root / ('Instant-Games_' + suffix + '.html')).read_bytes()
        if (record['status'] != 200 or record['sha256'] != digest
                or hashlib.sha256(raw).hexdigest() != digest or record['bytes'] != len(raw)
                or datetime.fromisoformat(record['retrievedAt']).tzinfo is None):
            raise ValueError('Unreviewed promotion source')
        evidence[suffix] = {key: record[key] for key in ('url', 'retrievedAt', 'sha256', 'bytes')}
        contents[suffix] = raw.decode('utf-8')
    parser = ComingSoon()
    parser.feed(contents['Coming-Soon'])
    if set(parser.games) != {'520', '532'}:
        raise ValueError('Reviewed coming-soon identities changed')
    return {
        'comingSoon': {'games': list(parser.games.values()), 'evidence': evidence['Coming-Soon'],
                       'coverage': 'Listed as coming soon at source observation; not current sales, inventory or a launch-date guarantee. Shared designs use one game identity. Complete prize tiers unavailable.'},
        'secondChance': {
            'evidence': evidence['Second-Chance-Drawing'],
            'summary': 'The source directs eligible instant-ticket holders to Players Club registration or login and its rules/entry site. Eligibility is not established for every ticket.',
            'rulesAndEntryUrl': 'https://www.deilottery.com/',
            'coverage': 'Source-linked information only; no registration, login, ticket submission or entry is performed. Detailed eligibility and current promotion rules must be checked at the official site; no complete promotions archive.',
        },
    }
