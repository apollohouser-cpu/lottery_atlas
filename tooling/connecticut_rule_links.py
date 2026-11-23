"""Extract official rule links, not PDF contents, from verified detail captures."""
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit

RULE_NAMES = {
    'powerball': 'Powerball', 'xsandos': 'PowerballXsAndOs',
    'megamillions': 'MegaMillions', 'mfl': 'MillionaireForLife',
    'lotto': 'Lotto', 'keno': 'KENO', 'cash5': 'Cash5',
    'play3': 'Play3', 'play4': 'Play4',
}


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = set()

    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            href = dict(attrs).get('href')
            if href:
                self.links.add(urljoin('https://ctlottery.com/', href))


def extract(html, game):
    parser = Links()
    parser.feed(html)
    prefix = RULE_NAMES[game] + '-OfficialGameRules-'
    candidates = [url for url in parser.links
                  if urlsplit(url).path.rsplit('/', 1)[-1].startswith(prefix)]
    if len(candidates) != 1:
        raise ValueError('Missing or ambiguous game rule link: ' + game)
    url = candidates[0]
    parts = urlsplit(url)
    if (parts.scheme != 'https' or parts.netloc != 'ctlottery.com' or
            not parts.path.startswith('/sites/default/files/') or
            not parts.path.endswith('.pdf') or parts.query or parts.fragment):
        raise ValueError('Unexpected official rule URL')
    return {'game': game, 'title': 'Official game rules', 'sourceUrl': url,
            'coverage': 'Rule link observed on captured official game page; '
                        'PDF contents are not bundled or validated by this link extraction.'}
