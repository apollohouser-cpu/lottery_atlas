"""Keep independent Powerball/Double Play schedules and source caveats."""
import hashlib
import json
from pathlib import Path
from lxml import html
from tooling.delaware_multiwin_report import text


def parse(raw, *, source_url):
    rules = json.loads(Path(__file__).with_name('delaware_powerball_schedule.json').read_text())
    tree = html.fromstring(raw)
    bodies = tree.xpath('//div[@class="tab-body-area"]')
    if source_url != rules['sourceUrl'] or tree.xpath('//title/text()') != [rules['title']] or len(bodies) != 1:
        raise ValueError('Wrong source/rule identity')
    body = bodies[0]
    if hashlib.sha256(text(body).encode()).hexdigest() != rules['auditedBodyTextSha256']:
        raise ValueError('Rule content changed; re-audit required')
    tables = body.xpath('.//table')
    if len(tables) != 2 or [len(t.xpath('./tbody/tr')) for t in tables] != [9, 9]:
        raise ValueError('Changed schedule structure')
    if [len(r.xpath('./td')) for r in tables[0].xpath('./tbody/tr')] != [4]+[8]*8 or any(len(r.xpath('./td')) != 3 for r in tables[1].xpath('./tbody/tr')):
        raise ValueError('Changed prize/multiplier columns')
    return rules
