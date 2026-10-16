"""Dated Nebraska regular prize reports; option families handled separately."""
from datetime import datetime
import json
from pathlib import Path
import re
from lxml import html
from tooling.nebraska_draw_results import parse_results, plain

SPECS = json.loads(Path(__file__).with_name('nebraska_report_specs.json').read_text())


def parse_regular_report(raw, family, *, today):
    if family not in SPECS:
        raise ValueError('Unsupported regular report family')
    results = parse_results(raw, family, today=today)
    tree = html.fromstring(raw)
    title = 'Powerball Xs & Os' if family == 'Powerball Xs and Os' else family
    headings = tree.xpath('//h2[contains(., "drawing results for")]')
    if len(headings) != 1:
        raise ValueError('Missing or ambiguous report heading')
    match = re.fullmatch(re.escape(title) + r' drawing results for (\d{2}/\d{2}/\d{4}), in Nebraska', plain(headings[0]))
    if not match:
        raise ValueError('Changed report family or geographic unit')
    stamp = datetime.strptime(match[1], '%m/%d/%Y').date().isoformat()
    if stamp != results[0]['drawDate']:
        raise ValueError('Report not associated with latest result')
    following = headings[0].getnext()
    while following is not None and not isinstance(following.tag, str):
        following = following.getnext()
    if following is None or following.tag != 'table':
        raise ValueError('Missing adjacent report table')
    captions = following.xpath('./caption')
    caption = plain(captions[0]) if len(captions) == 1 else ''
    if len(captions) > 1 or caption != SPECS[family]['caption']:
        raise ValueError('Changed report variant')
    rows = [[plain(c) for c in r.xpath('./th|./td')] for r in following.xpath('.//tr')]
    if not rows or rows[0] != ['Get', 'Prize', 'Odds', 'Winners']:
        raise ValueError('Changed report columns')
    expected = SPECS[family]['tiers']
    if len(rows) != len(expected) + 1:
        raise ValueError('Incomplete report tiers')
    tiers = []
    for cells, spec in zip(rows[1:], expected):
        if len(cells) != 4 or cells[:3] != spec:
            raise ValueError('Changed tier, prize or odds')
        if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)', cells[3]):
            raise ValueError('Invalid published winner count')
        tiers.append(dict(match=cells[0], prizeLabel=cells[1], oddsLabel=cells[2],
                          sourceWinners=int(cells[3].replace(',', ''))))
    return dict(family=family, group=results[0]['group'], drawDate=stamp,
                dateZone='America/Chicago', sourceUrl=results[0]['sourceUrl'],
                geographicUnit='Nebraska', countUnit='Winners (source label)',
                limitation='Source winner counts are not unique people or a complete claims history. Do not sum overlapping bet categories.',
                tiers=tiers)
