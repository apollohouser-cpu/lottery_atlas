"""Reviewed source rule text, preserving source discrepancies without resolving them."""
import copy
import json
from pathlib import Path
from lxml import html
from tooling.idaho_draw_schedules import parse_schedule

SPECS = json.loads(Path(__file__).with_name('idaho_draw_rule_specs.json').read_text())


def _extract(raw):
    doc = html.fromstring(raw)
    sections = doc.xpath('//*[@id="tab2"]')
    if len(sections) != 1:
        raise ValueError('Expected one Idaho rules section')
    section = sections[0]
    # Tables have a separate structural contract. Ignore executable/presentation
    # content, but retain all prose before and after the schedule container.
    for node in section.xpath('.//script|.//style|.//iframe|.//div[contains(concat(" ", normalize-space(@class), " "), " horizontal-prize-container ")]'):
        node.drop_tree()
    return ' '.join(section.text_content().split())


def parse_rules(raw, slug):
    if slug not in SPECS:
        raise ValueError('Unsupported Idaho rules')
    parse_schedule(raw, slug)
    if _extract(raw) != SPECS[slug]['sourceText']:
        raise ValueError('Changed Idaho rule text requires review')
    return copy.deepcopy(SPECS[slug])
