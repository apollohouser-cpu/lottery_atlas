"""2026 Raffle rules and daily promotion; no final-draw result inference."""
import copy
import json
import re
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo
from lxml import html

SPEC = json.loads(Path(__file__).with_name('idaho_raffle_spec.json').read_text())
SOURCE = 'https://www.idaholottery.com/games/raffle/idaho-1000000-raffle-2026'


def _text(n):
    return ' '.join(n.text_content().split())


def _extract(raw, as_of):
    doc = html.fromstring(raw)
    if doc.xpath('//head/title/text()') != ['Idaho $1,000,000 Raffle 2026 | Idaho Lottery']:
        raise ValueError('Wrong Raffle identity')
    sections, reports = [], []
    for key in ['tab2', 'tab3']:
        found = doc.xpath(f'//*[@id="{key}"]')
        if len(found) != 1: raise ValueError('Missing/duplicate Raffle section')
        section = found[0]
        rows = []
        # Only the source's paragraph + strong-number representation is accepted.
        for p in section.xpath('.//p[strong]'):
            text = _text(p)
            if not re.match(r'^(Oct|Nov)\b', text): continue
            match = re.fullmatch(r'(Oct|Nov) ([1-9]|[12][0-9]|3[01]) ([0-9]{6})', text)
            if not match or len(p.xpath('./strong')) != 1 or _text(p.xpath('./strong')[0]) != match[3]:
                raise ValueError('Malformed daily promotion')
            day = date(2026, 10 if match[1] == 'Oct' else 11, int(match[2]))
            if not date(2026,10,21) <= day <= min(as_of, date(2026,11,9)):
                raise ValueError('Invalid promotion date')
            if not 1 <= int(match[3]) <= 500000: raise ValueError('Invalid ticket number')
            rows.append({'date': day.isoformat(), 'ticketNumber': match[3]})
            p.drop_tree()
        if not rows or len({r['date'] for r in rows}) != len(rows):
            raise ValueError('Missing/duplicate daily promotion dates')
        reports.append(sorted(rows, key=lambda r:r['date']))
        sections.append(_text(section))
    if reports[0] != reports[1]: raise ValueError('Promotion copies disagree')
    tables = doc.xpath('//table')
    if len(tables) != 1: raise ValueError('Missing/duplicate Raffle schedule')
    table = [[_text(c) for c in r.xpath('./th|./td')] for r in tables[0].xpath('.//tr')]
    return {'sections': sections, 'table': table}, reports[0]


def parse_raffle(raw, *, as_of=None):
    as_of = as_of or datetime.now(ZoneInfo('America/Boise')).date()
    if as_of >= date(2026,12,29):
        raise ValueError('Final announcement period requires new source review')
    contract, promotions = _extract(raw, as_of)
    if contract != SPEC: raise ValueError('Changed Raffle rules/schedule requires review')
    return {'productType': 'raffle', 'edition': 2026, 'sourceUrl': SOURCE,
            'finalResult': None, 'finalResultStatus': 'not_yet_announced_in_reviewed_source',
            'dailyPromotions': promotions, 'sourceRules': copy.deepcopy(SPEC['sections']),
            'schedule': copy.deepcopy(SPEC['table']),
            'limitations': ['Daily promotional numbers are not final Raffle results.',
                'The printed top-tier odds 1:225000 conflict with the stated 500000-ticket limit and two prizes; no corrected odds are inferred.',
                'Announcement is December 29 at 12:20 pm MT or within four business days after the last ticket is sold, whichever is later.']}
