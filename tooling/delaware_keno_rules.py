"""Literal Keno spot schedules with unresolved source limits disclosed."""
import hashlib
import json
from pathlib import Path
from lxml import html
from tooling.delaware_multiwin_report import text


def parse(raw, *, source_url):
    rules = json.loads(Path(__file__).with_name('delaware_keno_schedule.json').read_text())
    tree = html.fromstring(raw)
    bodies = tree.xpath('//div[@class="col-md-9 content-body keno-body"]')
    if source_url != rules['sourceUrl'] or tree.xpath('//title/text()') != [rules['title']] or len(bodies) != 1:
        raise ValueError('Wrong Keno rule identity')
    body = bodies[0]
    if hashlib.sha256(text(body).encode()).hexdigest() != rules['auditedBodyTextSha256']:
        raise ValueError('Keno rule content changed; re-audit required')
    tables = body.xpath('.//table')
    if len(tables) != 11 or [len(t.xpath('./tbody/tr')) for t in tables] != [7,6,5,5,4,3,3,2,1,1,6]:
        raise ValueError('Changed spot/bonus structure')
    for spot, table in zip(range(10,0,-1), tables[:10]):
        if text(table.getprevious()) != f'{spot} spot game':
            raise ValueError('Changed spot identity')
        if any([c.get('data-label') for c in row.xpath('./td')] != ['Match','Prize'] for row in table.xpath('./tbody/tr')):
            raise ValueError('Changed tier labels')
    return rules
