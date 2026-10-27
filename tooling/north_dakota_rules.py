"""Literal reviewed North Dakota rule contracts, including merged table cells."""
import copy
from html.parser import HTMLParser
import json
from pathlib import Path

SPEC_PATH = Path(__file__).with_name('north_dakota_rule_specs.json')
VOID = {'img', 'br', 'hr', 'input', 'meta', 'link'}
ALLOWED = {'div', 'h2', 'h3', 'p', 'strong', 'b', 'em', 'i', 'u', 'span', 'sup', 'sub',
           'ul', 'ol', 'li', 'table', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td', 'a'} | VOID


class RuleSection(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.sections = []
        self.stack = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if not self.stack:
            if tag != 'div' or 'col-lg-8' not in attrs.get('class', '').split():
                return
            root = {'tag': tag, 'attrs': {}, 'children': []}
            self.sections.append(root)
            self.stack.append(root)
            return
        if tag not in ALLOWED:
            raise ValueError('Unexpected rule markup')
        kept = {k: v for k, v in attrs.items() if k in ('rowspan', 'colspan', 'href', 'src', 'alt')}
        for key in ('rowspan', 'colspan'):
            if key in kept and (not kept[key].isdigit() or not 1 <= int(kept[key]) <= 20):
                raise ValueError('Invalid rule cell span')
        node = {'tag': tag, 'attrs': kept, 'children': []}
        self.stack[-1]['children'].append(node)
        if tag not in VOID:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag not in VOID:
            self.handle_endtag(tag)

    def handle_endtag(self, tag):
        if not self.stack or tag in VOID:
            return
        if self.stack[-1]['tag'] != tag:
            raise ValueError('Unbalanced rule section')
        self.stack.pop()

    def handle_data(self, data):
        if self.stack:
            self.stack[-1]['children'].append(data)


def _normalize(node):
    # Join split character events before whitespace normalization so entities
    # and harmless HTML indentation cannot alter the canonical contract.
    children, pending = [], ''
    for child in node['children']:
        if isinstance(child, str):
            pending += child
        else:
            if pending.strip():
                children.append(' '.join(pending.split()))
            pending = ''
            children.append(_normalize(child))
    if pending.strip():
        children.append(' '.join(pending.split()))
    return {**node, 'children': children}


def extract_section(html):
    parser = RuleSection()
    parser.feed(html)
    parser.close()
    if parser.stack or len(parser.sections) != 1:
        raise ValueError('Missing/duplicate/unclosed rule section')
    return _normalize(parser.sections[0])


def parse_rules(html, game):
    specs = json.loads(SPEC_PATH.read_text())
    if game not in specs:
        raise ValueError('Unsupported North Dakota rules')
    actual = extract_section(html)
    if actual != specs[game]['document']:
        raise ValueError('Changed North Dakota rules require review')
    return {'game': game, 'coverage': 'Literal published rules and schedules, not dated payouts or counts.',
            **copy.deepcopy(specs[game])}
