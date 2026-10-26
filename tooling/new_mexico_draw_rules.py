"""Literal New Mexico HTML rule contracts, distinct from dated prize payouts."""
import copy
import json
from pathlib import Path
from lxml import html

PAGES = {
    'powerball': ('powerball', 'post-61'),
    'megamillions': ('mega-millions', 'post-27211'),
    'lottoamerica': ('lotto-america', 'post-92'),
    'roadrunnercash': ('roadrunner-cash', 'post-103'),
    'pick3plus': ('pick-3-plus', 'post-19456'),
    'pick4plus': ('pick-4-plus', 'post-19718'),
}
SPEC_PATH = Path(__file__).with_name('new_mexico_draw_rule_specs.json')


def plain(node):
    return ' '.join(node.text_content().split())


def span(cell, key):
    value = cell.get(key, '1')
    if not value.isdigit() or not 1 <= int(value) <= 20:
        raise ValueError('Invalid rule cell span')
    return int(value)


def extract(raw, game):
    if game not in PAGES:
        raise ValueError('Unsupported rules game')
    tree = html.fromstring(raw)
    articles = tree.xpath('//article')
    if len(articles) != 1 or articles[0].get('id') != PAGES[game][1]:
        raise ValueError('Changed rule page identity')
    article = articles[0]
    for node in article.xpath('.//script|.//style'):
        node.drop_tree()
    tables = []
    for table in article.xpath('.//table'):
        rows = []
        for tr in table.xpath('./tr|./thead/tr|./tbody/tr|./tfoot/tr'):
            cells = []
            for cell in tr.xpath('./td|./th'):
                cells.append(dict(text=plain(cell), rowspan=span(cell,'rowspan'),
                                  colspan=span(cell,'colspan'), header=cell.tag=='th',
                                  images=[dict(src=i.get('src'),alt=i.get('alt','')) for i in cell.xpath('.//img')]))
            if not cells:
                raise ValueError('Empty schedule row')
            rows.append(cells)
        if not rows:
            raise ValueError('Empty schedule')
        tables.append(rows)
    if not tables:
        raise ValueError('Missing schedules')
    # Keep the complete normalized prose including table text, so caveats cannot
    # disappear and layout changes cannot silently move text between contracts.
    return dict(text=plain(article), tables=tables)


def parse_rules(raw, game):
    actual = extract(raw, game)
    specs = json.loads(SPEC_PATH.read_text())
    if actual != specs.get(game):
        raise ValueError('Changed New Mexico rule/schedule requires review')
    slug = PAGES[game][0]
    return dict(game=game, sourceUrl=f'https://www.nmlottery.com/games/{slug}/how-to-play-{slug}/',
                coverage='Literal published rules and prize schedules, not actual dated payouts or winner counts. Pari-mutuel and variable-prize caveats apply.',
                **copy.deepcopy(actual))
