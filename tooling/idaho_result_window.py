"""Build a private bounded result window. Publication/retention is separate."""
from datetime import datetime, timedelta
import re
from lxml import html

from tooling.idaho_draw_results import GAMES, API, parse_results
from tooling.idaho_mfl_results import parse_results as parse_mfl


def source_dates(raw, slug, *, as_of):
    tree = html.fromstring(raw)
    if tree.xpath('//head/title/text()') != [GAMES[slug] + ' | Idaho Lottery']:
        raise ValueError('Wrong game page')
    tables = tree.xpath('//*[@id="tab4"]//table')
    if len(tables) != 1:
        raise ValueError('Missing/ambiguous history table')
    table = tables[0]
    headers = [' '.join(x.text_content().split()) for x in table.xpath('./thead/tr/th')]
    expected = ['Date', 'Winning Numbers', 'Multiplier', 'Jackpot'] if slug in ('powerball', 'lotto-america') else ['Date', 'Winning Numbers', 'Jackpot']
    if headers != expected:
        raise ValueError('Changed history headings')
    dates = []
    rows = table.xpath('./tbody/tr')
    for row in rows:
        cells = row.xpath('./td[@data-title="Date"]')
        if len(cells) != 1:
            raise ValueError('Missing/ambiguous history date')
        text = cells[0].text_content().strip()
        if not re.fullmatch(r'[0-9]{2}/[0-9]{2}/[0-9]{2}', text):
            raise ValueError('Malformed history date')
        value = datetime.strptime(text, '%m/%d/%y').date()
        if value > as_of or (dates and value >= dates[-1]):
            raise ValueError('Future/duplicate/reordered dates')
        dates.append(value)
    if slug in ('pick-3', 'pick-4') and len(dates) == 1:
        # The daily game's preceding date is only a request candidate. Its API
        # must independently return both sessions for that exact date.
        dates.append(dates[0] - timedelta(days=1))
    if len(dates) < 2:
        raise ValueError('Insufficient dates')
    return [d.isoformat() for d in dates[:2]]


def build_window(pages, fetch_json, *, as_of):
    required = set(GAMES) | {'millionaire-for-life'}
    if set(pages) != required:
        raise ValueError('Incomplete/extra game pages')
    results = []
    for slug in GAMES:
        for draw_date in source_dates(pages[slug], slug, as_of=as_of):
            results.extend(parse_results(fetch_json(API + slug + '/' + draw_date), slug, draw_date, as_of=as_of))
    results.extend(parse_mfl(pages['millionaire-for-life'], as_of=as_of))
    identities = {(r['group'], r['drawDate']) for r in results}
    groups = {r['group'] for r in results}
    if len(results) != 22 or len(identities) != 22 or len(groups) != 11:
        raise ValueError('Incomplete bounded result window')
    if any(sum(r['group'] == group for r in results) != 2 for group in groups):
        raise ValueError('Wrong per-group window')
    return {'state': 'Idaho', 'results': results,
            'coverage': 'Two dated results per group. Winner reports, schedules, jackpots and instant products are not included in this private stage.'}
