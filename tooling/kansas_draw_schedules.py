"""Literal Kansas CMS schedules; no calculated awards or winner counts."""
import json
import re
from lxml import html

# Audited official column order and row identities, not prize-value snapshots.
SCHEMAS = {'2-by-2': {'gameId': 5,
            'jackpotGameNumber': '5',
            'tables': [(['match', 'win', 'odds'],
                        ['2 Red and 2 White numbers',
                         '1 Red and 2 White numbers',
                         '2 Red and 1 White number',
                         '1 Red and 1 White number',
                         '0 Red and 2 White numbers',
                         '2 Red and 0 White numbers',
                         '0 Red and 1 White number',
                         '1 Red and 0 White numbers'])]},
 'lotto-america': {'gameId': 3,
                   'jackpotGameNumber': '3',
                   'tables': [(['match', 'win', 'odds'],
                               ['5 numbers and the Star Ball',
                                '5 numbers but not the Star Ball',
                                '4 numbers and the Star Ball',
                                '4 numbers but not the Star Ball',
                                '3 numbers and the Star Ball',
                                '3 numbers but not the Star Ball',
                                '2 numbers and the Star Ball',
                                '1 number and the Star Ball',
                                'Only the Star Ball'])]},
 'megamillions': {'gameId': 12,
                  'jackpotGameNumber': '12',
                  'tables': [(['match', 'win', 'odds'],
                              ['5 numbers and the Mega Ball',
                               '5 numbers but not the Mega Ball',
                               '4 numbers and the Mega Ball',
                               '4 numbers but not the Mega Ball',
                               '3 numbers and the Mega Ball',
                               '3 numbers but not the Mega Ball',
                               '2 numbers and the Mega Ball',
                               '1 number and the Mega Ball',
                               'Only the Mega Ball']),
                             (['multiplier', 'odds'],
                              ['10x', '5x', '4x', '3x', '2x', 'Avg. Multiplier'])]},
 'millionaire-for-life': {'gameId': 14,
                          'jackpotGameNumber': '14',
                          'tables': [(['match', 'prize', 'odds'],
                                      ['5 numbers and the Millionaire Ball',
                                       '5 numbers',
                                       '4 numbers and the Millionaire Ball',
                                       '4 numbers',
                                       '3 numbers and the Millionaire Ball',
                                       '3 numbers',
                                       '2 numbers and the Millionaire Ball',
                                       '2 numbers',
                                       '1 number and the Millionaire Ball'])]},
 'pick-3': {'gameId': 10,
            'jackpotGameNumber': '9,10',
            'tables': [(['type of play',
                         'example: You Play',
                         'you win if we draw',
                         'odds',
                         '1$ Wager'],
                        ['Exact order (Straight)',
                         'Any order (6-way box)',
                         'Any order (3-way box) (Where two digits are the same)'])]},
 'powerball': {'gameId': 1,
               'jackpotGameNumber': '1',
               'tables': [(['match', 'Powerball Prize', 'Double Play Prize', 'odds'],
                           ['5 numbers and the Powerball',
                            '5 numbers but not the Powerball',
                            '4 numbers and the Powerball',
                            '4 numbers but not the Powerball',
                            '3 numbers and the Powerball',
                            '3 numbers but not the Powerball',
                            '2 numbers and the Powerball',
                            '1 number and the Powerball',
                            'Only the Powerball'])]},
 'powerball-xs-and-os': {'gameId': 15,
                         'jackpotGameNumber': '15',
                         'tables': [(['match', 'win', 'odds'],
                                     ['All eight (8)',
                                      'Any seven (7)',
                                      'Any six (6)',
                                      'Any five (5)',
                                      'Any four (4)'])]},
 'super-kansas-cash': {'gameId': 8,
                       'jackpotGameNumber': '8',
                       'tables': [(['match', 'win', 'odds'],
                                   ['5 numbers and the Cash Ball',
                                    '5 numbers but not the Cash Ball',
                                    '4 numbers and the Cash Ball',
                                    '4 numbers but not the Cash Ball',
                                    '3 numbers and the Cash Ball',
                                    '3 numbers but not the Cash Ball',
                                    '2 numbers and the Cash Ball',
                                    '1 number and the Cash Ball'])]}}


def cms_from_html(raw):
    chunks = []
    for script in html.fromstring(raw).xpath('//script[not(@src)]/text()'):
        match = re.fullmatch(r'self\.__next_f\.push\((\[.*\])\)', script, re.S)
        if match:
            part = json.loads(match[1])
            if len(part) == 2 and part[0] == 1 and isinstance(part[1], str):
                chunks.append(part[1])
    payload = ''.join(chunks)
    if payload.count('"cms":') != 1:
        raise ValueError('Missing or ambiguous detail CMS')
    cms = json.JSONDecoder().raw_decode(payload.split('"cms":', 1)[1])[0]
    # Flight long-text records use hexadecimal UTF-8 byte lengths, not character
    # lengths. Resolve only rich-text leaf references, never arbitrary CMS strings.
    def resolve(node):
        if isinstance(node, dict):
            value = node.get('value')
            if node.get('nodeType') == 'text' and isinstance(value, str) and re.fullmatch(r'\$[0-9a-f]+', value):
                records = list(re.finditer(r'(?:^|\n)' + re.escape(value[1:]) + r':T([0-9a-f]+),', payload))
                if len(records) != 1:
                    raise ValueError('Missing or ambiguous Flight text reference')
                record = records[0]
                length = int(record[1], 16)
                raw_text = payload[record.end():].encode('utf-8')[:length]
                try:
                    text = raw_text.decode('utf-8')
                except UnicodeDecodeError as exc:
                    raise ValueError('Invalid Flight text byte boundary') from exc
                if len(raw_text) != length:
                    raise ValueError('Truncated Flight text')
                node['value'] = text
            for child in node.values():
                resolve(child)
        elif isinstance(node, list):
            for child in node:
                resolve(child)
    resolve(cms)
    return cms


def rich_text(value):
    if value is None:
        return []
    if not isinstance(value, dict) or not isinstance(value.get('json'), dict):
        raise ValueError('Missing rich text document')
    def visit(node):
        kind = node.get('nodeType')
        if kind == 'text':
            if not isinstance(node.get('value'), str):
                raise ValueError('Invalid source text')
            return node['value']
        if kind not in {'document', 'paragraph', 'unordered-list', 'ordered-list', 'list-item',
                        'hyperlink', 'heading-1', 'heading-2', 'heading-3', 'heading-4',
                        'heading-5', 'heading-6', 'hr'}:
            raise ValueError('Unsupported rich text structure')
        children = node.get('content')
        if not isinstance(children, list):
            raise ValueError('Invalid source content')
        return ''.join(visit(c) for c in children) + ('\n' if kind not in {'hyperlink'} else '')
    return [line.strip() for line in visit(value['json']).splitlines() if line.strip()]


def parse_schedule(cms, slug):
    schema = SCHEMAS[slug]
    if not isinstance(cms, dict) or cms.get('slug') != slug or type(cms.get('gameId')) is not int or cms['gameId'] != schema['gameId'] or cms.get('jackpotGameNumber') != schema['jackpotGameNumber']:
        raise ValueError('Wrong schedule game identity')
    tables = cms.get('prizeLegend')
    if not isinstance(tables, list) or len(tables) != len(schema['tables']):
        raise ValueError('Missing schedule tables')
    output = []
    for table, (columns, identities) in zip(tables, schema['tables']):
        if table.get('columnOrder') != columns:
            raise ValueError('Changed schedule columns')
        rows = table.get('matches')
        if not isinstance(rows, list) or len(rows) != len(identities):
            raise ValueError('Missing schedule rows')
        values = []
        for row, identity in zip(rows, identities):
            if not isinstance(row, dict) or set(row) != set(columns) or row[columns[0]] != identity:
                raise ValueError('Wrong schedule row identity/columns')
            cells = []
            for column in columns:
                cell = row[column]
                if not isinstance(cell, str) or not cell.strip():
                    raise ValueError('Empty schedule cell')
                if '$' in cell and not re.search(r'\$\$?\d[\d,]*(?:\.\d{2})?', cell):
                    raise ValueError('Invalid source money label')
                cells.append(cell)
            values.append(cells)
        output.append({'columns': columns, 'rows': values,
                       'description': table.get('description', ''), 'footer': table.get('footer', '')})
    qualifications = rich_text(cms.get('prizeLegendDescription'))
    rules = rich_text(cms.get('howToPlay'))
    disclaimer = rich_text(cms.get('disclaimer'))
    if not rules or (slug != 'pick-3' and not qualifications):
        raise ValueError('Missing source qualifications')
    required = {
        'powerball': ['pari-mutuel', '$150 million or less', 'Power Play does not apply to Double Play', 'divided between multiple winners'],
        'lotto-america': ['pari-mutuel', 'divided between multiple winners'],
        'megamillions': ['30 annual installments', 'Cash Option', 'divided between multiple winners'],
        'millionaire-for-life': ['Cash option prizes', '$18,000,000', '$2,200,000'],
        'super-kansas-cash': ['pari-mutual', 'divided between multiple winners'],
        '2-by-2': ['pari-mutuel', '7 consecutive days'],
        'powerball-xs-and-os': ['not based on', 'NFL games', 'liability limits'],
        'pick-3': ['$1 wager', 'MID', 'EVE', 'limited to the cost'],
    }[slug]
    qualification_text = ' '.join(rules if slug == 'pick-3' else qualifications)
    if any(phrase not in qualification_text for phrase in required):
        raise ValueError('Required source qualification missing')
    for table in output:
        if not isinstance(table['description'], str) or not isinstance(table['footer'], str):
            raise ValueError('Invalid schedule notes')
    warnings = ['Source CMS currency strings can contain a doubled dollar marker; literal source values are retained.']
    if slug == 'pick-3':
        warnings.append('Source prose and table differ in their Any Order box descriptions; both are retained without resolving the source inconsistency.')
    return {'sourceUrl': f'https://playonkansas.com/games/draw-games/{slug}',
            'tables': output, 'qualifications': qualifications, 'rules': rules,
            'disclaimer': disclaimer,
            'coverage': 'Literal published prize schedule, not actual winners or paid prizes. Source currency markers and qualifications are retained; no cash conversion.',
            'sourceWarnings': warnings}
