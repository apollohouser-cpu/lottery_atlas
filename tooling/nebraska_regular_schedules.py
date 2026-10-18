"""Literal regular-family instructions, bet schedules and qualifications.

These undated rules are separate from dated prize reports. Reviewed snapshots
fail closed on changes, including removed qualifications or shifted table cells.
"""
import json
from pathlib import Path
from lxml import html
from tooling.nebraska_draw_results import plain

SPEC_PATH = Path(__file__).with_name('nebraska_regular_schedule_specs.json')
FAMILIES = ('Pick 5', 'Millionaire for Life', 'Pick 3', 'Pick 4', 'MyDaY',
            'Powerball Xs and Os')


def extract_blocks(raw):
    tree = html.fromstring(raw)
    roots = tree.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," ld_left ")]')
    if len(roots) != 1:
        raise ValueError('Missing or ambiguous rules section')
    blocks = []

    def visit(node):
        if not isinstance(node.tag, str):
            return
        if node.tag in ('div', 'section'):
            if (node.text or '').strip():
                raise ValueError('Unexpected unstructured rules text')
            for child in node:
                visit(child)
                if (child.tail or '').strip():
                    raise ValueError('Unexpected rules tail text')
        elif node.tag in ('h2', 'h3', 'p', 'ul', 'ol'):
            if plain(node):
                # Keep physical line breaks in Pick 3's prose bet schedule.
                clone = html.fromstring(html.tostring(node))
                for br in clone.xpath('.//br'):
                    br.tail = '\n' + (br.tail or '')
                lines = [' '.join(line.split()) for line in clone.text_content().splitlines()]
                blocks.append(dict(kind='heading' if node.tag.startswith('h') else 'text',
                                   text='\n'.join(line for line in lines if line)))
        elif node.tag == 'table':
            rows = [[plain(c) for c in row.xpath('./th|./td')]
                    for row in node.xpath('.//tr')]
            if not rows or not rows[0] or any(len(row) != len(rows[0]) for row in rows):
                raise ValueError('Incomplete schedule table')
            blocks.append(dict(kind='table', columns=rows[0], rows=rows[1:]))
        elif node.tag not in ('img', 'br'):
            raise ValueError('Unexpected rules element')

    visit(roots[0])
    return blocks


def parse_regular_schedule(raw, family):
    if family not in FAMILIES:
        raise ValueError('Unsupported regular schedule family')
    blocks = extract_blocks(raw)
    expected = json.loads(SPEC_PATH.read_text())[family]
    if blocks != expected:
        raise ValueError('Changed regular schedule or qualification')
    return blocks
