"""Validate observed numbered product links; never infer inventory or URL slugs."""
import re
from urllib.parse import urlsplit, urljoin

ORIGIN = 'https://www.arizonalottery.com'


def parse_navigation(capture, kind, expected_ids):
    if kind not in ('scratchers', 'fast-play'):
        raise ValueError('Unsupported catalog')
    root = f'{ORIGIN}/{kind}/'
    if capture.get('sourceUrl') != root or capture.get('captureKind') != 'browser-dom-anchor-observation':
        raise ValueError('Invalid capture provenance')
    if not isinstance(capture.get('capturedAt'), str) or not capture['capturedAt']:
        raise ValueError('Missing acquisition time')
    expected = set(expected_ids)
    if not expected or any(not isinstance(x, str) or not x.isdigit() for x in expected):
        raise ValueError('Invalid expected identities')
    rows = capture.get('links')
    if not isinstance(rows, list) or not rows:
        raise ValueError('Missing product links')
    products = {}
    for row in rows:
        text, href = row.get('text'), row.get('href')
        if not isinstance(text, str) or not isinstance(href, str):
            raise ValueError('Invalid link fields')
        match = re.fullmatch(r'#?([0-9]+)\s+(.+)', text)
        if not match or '…' in href or any(c.isspace() for c in href):
            raise ValueError('Incomplete product identity/link')
        number, title = match.groups()
        url = urljoin(root, href)
        parts = urlsplit(url)
        if (parts.scheme != 'https' or parts.netloc != 'www.arizonalottery.com'
                or parts.query or parts.fragment
                or not re.fullmatch(r'/' + kind + '/' + re.escape(number) + r'-[a-z0-9-]+/', parts.path)):
            raise ValueError('Source URL does not match printed identity')
        if number in products:
            raise ValueError('Duplicate printed identity')
        products[number] = {'gameNumber': number, 'title': title, 'sourceUrl': url}
    if set(products) != expected:
        raise ValueError('Catalog identity set changed or incomplete')
    return list(products.values())
