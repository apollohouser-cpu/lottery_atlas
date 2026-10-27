"""Reviewed catalog cards; literal marketing text is not winner-count evidence."""
from html.parser import HTMLParser
import json
from pathlib import Path

URL = 'https://www.lottery.nd.gov/games/'
SPEC_PATH = Path(__file__).with_name('north_dakota_catalog_spec.json')


class Catalog(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.depth = 0
        self.cards = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if not self.depth:
            if tag != 'div' or 'gamepage' not in attrs.get('class', '').split():
                return
            self.depth = 1
            self.cards.append([])
        else:
            if tag == 'div': self.depth += 1
        self.cards[-1].append(['start', tag, {k:v for k,v in attrs.items() if k in ('href','src','alt')}])

    def handle_endtag(self, tag):
        if self.depth:
            self.cards[-1].append(['end', tag])
            if tag == 'div': self.depth -= 1

    def handle_data(self, text):
        if self.depth and text.strip():
            self.cards[-1].append(['text', ' '.join(text.split())])


def extract(html):
    parser = Catalog()
    parser.feed(html)
    parser.close()
    if parser.depth or len(parser.cards) != 6:
        raise ValueError('Missing, extra or unclosed catalog cards')
    return parser.cards


def parse_catalog(html):
    if extract(html) != json.loads(SPEC_PATH.read_text()):
        raise ValueError('Current catalog/status changed; review required')
    return dict(sourceUrl=URL, currentGames=['powerball','mega-millions','millionaire-for-life','lotto-america','2by2'],
                retired=[dict(game='lucky-for-life', finalDrawDate='2026-02-21')],
                note='Catalog and retired status only. Promotional winner language is not verified counts or prize availability.')
