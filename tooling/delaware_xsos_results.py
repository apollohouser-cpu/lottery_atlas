"""Preserve source-labelled team logos, not numerical balls or NFL outcomes."""
from datetime import date, datetime
import re
from lxml import html
from tooling.delaware_keno_results import nodes


def parse(raw, *, year, month, source_url, observed_date):
    start = date(year, month, 1)
    if source_url != f'https://www.delottery.com/Winning-Numbers/Search-Winners/{year}/{month}/PowerballXsAndOs' or start > observed_date:
        raise ValueError('Source/month mismatch')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != [f'{start:%B %Y} - Powerball Xs And Os - Search Winners | Delaware Lottery']:
        raise ValueError('Wrong monthly identity')
    containers = nodes(tree, 'pb-xsos-draw-results')
    if len(containers) != 1:
        raise ValueError('Missing/ambiguous results')
    cards = containers[0].xpath('./article')
    if not cards or len(cards) != len(containers[0]):
        raise ValueError('Empty/changed result container')
    results, previous = [], None
    for card in cards:
        headings = card.xpath('./h3')
        lists = nodes(card, 'pb-xsos-draw-logos')
        if len(headings) != 1 or len(lists) != 1 or len(card) != 2:
            raise ValueError('Changed draw structure')
        literal = headings[0].text_content().strip()
        draw = datetime.strptime(literal, '%B %d, %Y').date()
        if (draw.year, draw.month) != (year, month) or draw > observed_date or (previous and draw >= previous):
            raise ValueError('Invalid date bounds/order')
        previous = draw
        if lists[0].get('aria-label') != 'Winning logos for ' + literal:
            raise ValueError('Logo/date mismatch')
        logos = nodes(lists[0], 'pb-xsos-draw-logo')
        if len(logos) != 8 or len(lists[0]) != 8:
            raise ValueError('Expected eight logos')
        teams = []
        for logo in logos:
            spans, images = logo.xpath('./span'), logo.xpath('./img')
            if len(spans) != 2 or len(images) != 1 or len(logo) != 3:
                raise ValueError('Changed logo structure')
            code, name = [n.text_content().strip() for n in spans]
            if not re.fullmatch(r'[A-Z]{2,3}', code) or not name or spans[1].get('class') != 'sr-only':
                raise ValueError('Missing source team identity')
            path = '/Winning-Numbers/Powerball-Xs-And-Os-Logo/' + code.lower()
            if images[0].get('src') != path:
                raise ValueError('Team/image mismatch')
            teams.append({'code': code, 'name': name, 'imageUrl': 'https://www.delottery.com' + path})
        if len({t['code'] for t in teams}) != 8 or len({t['name'] for t in teams}) != 8:
            raise ValueError('Duplicate team identity')
        results.append({'game': 'Powerball Xs & Os', 'drawDate': draw.isoformat(), 'teams': teams})
    return {'sourceUrl': source_url, 'results': results,
            'coverage': 'Published winning-logo observations are unofficial; tickets remain proof of winning. Random draws, not NFL outcomes.'}
