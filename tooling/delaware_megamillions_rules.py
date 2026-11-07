"""Audited literal schedule; changed semantic content requires review."""
import hashlib
import json
from pathlib import Path
from lxml import html
from tooling.delaware_multiwin_report import text


def parse(raw, *, source_url):
    rule = json.loads(Path(__file__).with_name('delaware_megamillions_schedule.json').read_text())
    tree = html.fromstring(raw)
    bodies = tree.xpath('//div[@class="tab-body-area"]')
    if source_url != rule['sourceUrl'] or tree.xpath('//title/text()') != [rule['title']] or len(bodies) != 1:
        raise ValueError('Wrong source/rule identity')
    if hashlib.sha256(text(bodies[0]).encode()).hexdigest() != rule['auditedBodyTextSha256']:
        raise ValueError('Rule content changed; re-audit required')
    tables = bodies[0].xpath('.//table')
    if len(tables) != 2 or len(tables[0].xpath('./tbody/tr')) != 9 or len(tables[1].xpath('./tbody/tr')) != 6:
        raise ValueError('Changed schedule structure')
    return rule
