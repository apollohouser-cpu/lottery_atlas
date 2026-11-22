"""Inspect CT's embedded draw-source inventory; never publish claims or payouts.

React Flight references are retained literally. This reconnaissance helper is
not a draw importer and must not interpret overloaded generic API field names.
"""
import argparse
from html.parser import HTMLParser
import json
from pathlib import Path
import re

EXPECTED = {'powerball', 'xsandos', 'megamillions', 'mfl', 'lotto',
            'keno', 'cash5', 'play3', 'play4'}


class Scripts(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.active = False
        self.current = []
        self.scripts = []

    def handle_starttag(self, tag, attrs):
        if tag == 'script':
            self.active = True
            self.current = []

    def handle_data(self, data):
        if self.active:
            self.current.append(data)

    def handle_endtag(self, tag):
        if tag == 'script' and self.active:
            self.scripts.append(''.join(self.current))
            self.active = False


def draw_inventory(raw):
    parser = Scripts()
    parser.feed(raw)
    chunks = []
    for script in parser.scripts:
        match = re.fullmatch(r'self\.__next_f\.push\((\[.*\])\)', script, re.S)
        if match:
            payload = json.loads(match[1])
            if len(payload) == 2 and payload[0] == 1 and isinstance(payload[1], str):
                chunks.append(payload[1])
    flight = ''.join(chunks)
    candidates = []
    for match in re.finditer(r'"games":\s*\[', flight):
        games, _ = json.JSONDecoder().raw_decode(flight[match.end()-1:])
        if games and isinstance(games[0], dict) and 'apiSlug' in games[0]:
            candidates.append(games)
    if len(candidates) != 1:
        raise ValueError('Missing or ambiguous draw inventory')
    games = candidates[0]
    slugs = [game.get('apiSlug') for game in games]
    if len(slugs) != len(set(slugs)) or set(slugs) != EXPECTED:
        raise ValueError('Changed or duplicate draw inventory; reconcile scope')
    for game in games:
        if not isinstance(game.get('title'), str) or not game['title'].strip():
            raise ValueError('Missing game title')
        route = game.get('detailsUrl', '')
        if not re.fullmatch(r'/games/draw-games/[a-z0-9-]+', route):
            raise ValueError('Unexpected detail route')
    return games


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    games = draw_inventory(args.capture.read_text())
    args.output.write_text(json.dumps({
        'status': 'source reconnaissance only; not validated app results',
        'games': games,
    }, indent=2) + '\n')


if __name__ == '__main__':
    main()
