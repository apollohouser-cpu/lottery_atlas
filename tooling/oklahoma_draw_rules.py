"""Fail-closed literal Oklahoma rule and schedule contracts, not dated payouts."""
import copy
import json
from pathlib import Path
from import_oklahoma_draws import CONTRACTS, SOURCE
from import_oklahoma_scratch_catalog import embedded

SOURCE_NOTES = {
    'pick3': 'Source disclaimer lists Midday and Evening cutoffs; how-to-play prose gives only an evening cutoff. Result session identity is unavailable.',
    'millionaire-for-life': 'Source how-to-play cutoff and disclaimer cutoff differ; retain both literal source statements.',
    'powerball-xs-os': 'Source legend prose lists both 1 in 12 and 1 in 8.47 overall odds. No resolved overall odds are inferred.',
    'lotto-america': 'The source SB-only row lists 1 in 160.94 in each schedule. This literal source value is not recalculated or corrected.',
}

SPEC_PATH = Path(__file__).with_name('oklahoma_draw_rule_specs.json')
PROSE_FIELDS = ('howToPlay', 'disclaimer', 'prizeLegendDescription', 'prizeLegendPrimaryDescription')


def prose(value):
    if value is None:
        return None
    if not isinstance(value, dict) or set(value) not in ({'json'}, {'json', 'links'}):
        raise ValueError('Changed rich text envelope')

    if 'links' in value and value['links'] != {'assets': {'hyperlink': []}}:
        raise ValueError('Unreviewed rule links')

    def node(item):
        if not isinstance(item, dict) or item.get('data') != {}:
            raise ValueError('Unreviewed rich text data or linked asset')
        kind = item.get('nodeType')
        if kind == 'text':
            if not isinstance(item.get('value'), str):
                raise ValueError('Missing rule text')
            return {'type': kind, 'text': ' '.join(item['value'].split())}
        if kind not in {'document', 'paragraph', 'unordered-list', 'ordered-list', 'list-item'}:
            raise ValueError('Unreviewed rule node')
        if not isinstance(item.get('content'), list):
            raise ValueError('Missing rule content')
        return {'type': kind, 'children': [node(child) for child in item['content']]}

    return node(value['json'])


def extract(cms, slug):
    if slug not in CONTRACTS:
        raise ValueError('Unknown rules game')
    gid = CONTRACTS[slug][0]
    if type(cms.get('gameId')) is not int or cms['gameId'] != gid or cms.get('slug') != slug or cms.get('gameNumber') != str(gid):
        raise ValueError('Rules identity mismatch')
    if 'endDate' not in cms or cms['endDate'] is not None:
        raise ValueError('Changed rules eligibility')
    fields = ('title', 'drawTimes', 'overallOdds', 'prizeLegend') + PROSE_FIELDS
    if any(key not in cms for key in fields):
        raise ValueError('Missing rule or schedule field')
    result = {key: copy.deepcopy(cms[key]) for key in fields if key not in PROSE_FIELDS}
    result.update({key: prose(cms[key]) for key in PROSE_FIELDS})
    return result


def parse_rules(raw, slug):
    cms = embedded(raw, 'cms')
    if not isinstance(cms, dict):
        raise ValueError('Invalid rules CMS')
    actual = extract(cms, slug)
    specs = json.loads(SPEC_PATH.read_text())
    if slug not in specs or actual != specs[slug]:
        raise ValueError('Changed Oklahoma rule/schedule requires review')
    # Return a copy so consumers cannot change the validation contract.
    return dict(game=slug, sourceUrl=SOURCE+slug, sourceNote=SOURCE_NOTES.get(slug), **copy.deepcopy(actual))
