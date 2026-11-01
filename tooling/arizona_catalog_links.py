"""Validate observed numbered product links; never infer inventory or URL slugs."""
import re
from datetime import datetime
from urllib.parse import urlsplit, urljoin

ORIGIN = 'https://www.arizonalottery.com'


def parse_navigation(capture, kind, expected_ids):
    if not isinstance(capture, dict):
        raise ValueError('Invalid capture')
    if kind not in ('scratchers', 'fast-play'):
        raise ValueError('Unsupported catalog')
    root = f'{ORIGIN}/{kind}/'
    if capture.get('sourceUrl') != root or capture.get('captureKind') != 'browser-dom-anchor-observation':
        raise ValueError('Invalid capture provenance')
    if not isinstance(capture.get('capturedAt'), str) or not capture['capturedAt']:
        raise ValueError('Missing acquisition time')
    try:
        acquired = datetime.fromisoformat(capture['capturedAt'].replace('Z', '+00:00'))
    except ValueError as exc:
        raise ValueError('Invalid acquisition time') from exc
    if acquired.tzinfo is None:
        raise ValueError('Acquisition time requires timezone')
    expected = set(expected_ids)
    if not expected or any(not isinstance(x, str) or not x.isdigit() for x in expected):
        raise ValueError('Invalid expected identities')
    rows = capture.get('links')
    if not isinstance(rows, list) or not rows:
        raise ValueError('Missing product links')
    products = {}
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError('Invalid link row')
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


def validate_continuity(products, baseline):
    """Require reviewed identity, title and source continuity on later captures."""
    def index(rows):
        result = {}
        for row in rows:
            if (not isinstance(row, dict)
                    or set(row) != {'gameNumber', 'title', 'sourceUrl'}
                    or not all(isinstance(v, str) and v for v in row.values())
                    or row['gameNumber'] in result):
                raise ValueError('Invalid continuity record')
            result[row['gameNumber']] = row
        if not result:
            raise ValueError('Empty continuity baseline')
        return result
    if index(products) != index(baseline):
        raise ValueError('Catalog identity/title/source changed; review required')
