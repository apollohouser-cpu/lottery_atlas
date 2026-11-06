"""Bind visual symbol reviews to retained rules and reconstruct inline wording.

Private screenshots/DOM stay private. No filename-derived labels or network IO.
"""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
from urllib.parse import urljoin


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def compact(text):
    return ''.join(text.split()).casefold()


class InlineRules(HTMLParser):
    def __init__(self, source, symbols):
        super().__init__(convert_charrefs=True)
        self.source, self.symbols = source, symbols
        self.plain, self.resolved, self.images = [], [], []

    def boundary(self):
        self.plain.append('\n')
        self.resolved.append('\n')

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in {'script', 'style', 'iframe', 'object'}:
            raise ValueError('Unsupported content in reviewed rule section')
        if tag == 'img':
            image = {'src': urljoin(self.source, attrs.get('src', '')), 'alt': attrs.get('alt', '')}
            index = len(self.images)
            if index >= len(self.symbols):
                raise ValueError('Unreviewed inline image')
            symbol = self.symbols[index]
            if image != {k: symbol[k] for k in ('src', 'alt')}:
                raise ValueError('Inline image order/source changed')
            label = symbol.get('visualLabel')
            if not isinstance(label, str) or not label.strip() or any(c in label for c in '\n[]'):
                raise ValueError('Missing or invalid reviewed symbol label')
            self.images.append(image)
            self.resolved.append('[symbol: ' + label + ']')
        elif tag in {'div', 'p', 'h2', 'h3', 'li', 'br'}:
            self.boundary()

    def handle_endtag(self, tag):
        if tag in {'div', 'p', 'h2', 'h3', 'li'}:
            self.boundary()

    def handle_data(self, text):
        self.plain.append(text)
        self.resolved.append(text)


def reconstruct(product, review, dom):
    source = product['sourceUrl']
    rules = product['rules']
    if review['sourceUrl'] != source or dom['sourceUrl'].split('#')[0] != source:
        raise ValueError('Reviewed rule source mismatch')
    if review['rulesSha256'] != digest(rules):
        raise ValueError('Reviewed source rules changed')
    if dom['images'] != rules['images'] or compact(dom['text']) != compact(rules['text']):
        raise ValueError('DOM does not match retained rules')
    parser = InlineRules(source, review['symbols'])
    parser.feed(dom['html'])
    parser.close()
    if parser.images != rules['images'] or len(parser.images) != len(review['symbols']):
        raise ValueError('Missing or extra reviewed symbols')
    if compact(''.join(parser.plain)) != compact(rules['text']):
        raise ValueError('Inline HTML wording changed')
    text = '\n'.join(' '.join(line.split()) for line in ''.join(parser.resolved).splitlines() if line.strip())
    return {'status': 'reviewed-symbol-text', 'text': text, 'sourceUrl': source,
            'reason': 'Bracketed symbol descriptions were visually checked against official illustrated rules.',
            'reviewedAt': review['reviewedAt'], 'sourceRulesSha256': review['rulesSha256']}


def load_reviews(directory, products):
    directory = Path(directory)
    reviews = json.loads((directory / 'reviewed-symbols.json').read_text())
    expected = {p['sourceUrl']: p for rows in products.values() for p in rows if p['rules']['images']}
    resolved = {}
    for review in reviews:
        source = review['sourceUrl']
        if source not in expected or source in resolved:
            raise ValueError('Unexpected or duplicate reviewed product')
        number = review['gameNumber']
        if not isinstance(number, str) or not number.isdigit():
            raise ValueError('Invalid review evidence key')
        for suffix, field in [('dom.json', 'domSha256'), ('visual.png', 'screenshotSha256')]:
            raw = (directory / f'{number}-{suffix}').read_bytes()
            if hashlib.sha256(raw).hexdigest() != review[field]:
                raise ValueError('Private review evidence changed')
        dom = json.loads((directory / f'{number}-dom.json').read_text())
        resolved[source] = reconstruct(expected[source], review, dom)
    if resolved.keys() != expected.keys():
        raise ValueError('Incomplete image-dependent rule review')
    return resolved
