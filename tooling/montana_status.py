"""Gate the reviewed product navigation; advertising is not a sales-status feed."""
import copy
import json
from pathlib import Path
from tooling.montana_rules import Sections, parse_rules

SPEC_PATH = Path(__file__).with_name('montana_status_spec.json')

def extract_navigation(html):
    parser = Sections(['games'])
    parser.feed(html)
    parser.close()
    if (parser.titles != ['Games - Montana Lottery'] or parser.root is not None
            or parser.title is not None or len(parser.sections) != 1):
        raise ValueError('Missing, duplicate or invalid Montana games navigation')
    return parser.sections

def parse_status(games_html, millionaire_html):
    spec = json.loads(SPEC_PATH.read_text())
    if extract_navigation(games_html) != spec['navigation']:
        raise ValueError('Changed Montana product navigation requires scope review')
    # The reviewed MFL prose establishes the retired Lucky for Life boundary.
    # Revalidate the original contract, never infer retirement from link absence.
    parse_rules(millionaire_html, 'millionaire-for-life')
    return copy.deepcopy(spec['coverage'])
