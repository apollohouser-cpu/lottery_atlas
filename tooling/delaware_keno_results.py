"""Parse official date-search observations without inventing timezone instants."""
from datetime import datetime
import re
from lxml import html

SOURCE = 'https://www.delottery.com/Keno/Winning-Numbers/By-Date'


def nodes(node, cls):
    return node.xpath('.//*[contains(concat(" ",normalize-space(@class)," ")," '+cls+' ")]')


def one_text(node, cls):
    matches = nodes(node, cls)
    if len(matches) != 1 or len(matches[0].xpath('./strong')) != 1:
        raise ValueError('Missing or duplicated result metadata')
    return matches[0].xpath('./strong')[0].text_content().strip()


def parse(raw, *, source_url, requested_date, observed_date):
    if source_url != SOURCE or requested_date > observed_date:
        raise ValueError('Invalid source or requested date')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != ['How Do I Check My Numbers? | Delaware Lottery']:
        raise ValueError('Unexpected page identity')
    dates = [n.text_content().strip() for n in tree.xpath('//h2')
             if n.text_content().strip().startswith('Winning Numbers for ')]
    expected = 'Winning Numbers for ' + requested_date.strftime('%B %d, %Y')
    if dates != [expected]:
        raise ValueError('Result date does not match request')
    rows = nodes(tree, 'keno-results_row')
    if not rows:
        raise ValueError('No observed Keno results')
    result = []
    previous_id = previous_time = None
    for row in rows:
        identity = one_text(row, 'keno-results_draw-number')
        time_text = one_text(row, 'keno-results_draw-time')
        multiplier = one_text(row, 'keno-results_multiplier')
        if not re.fullmatch(r'[1-9]\d*', identity):
            raise ValueError('Invalid game number')
        if not re.fullmatch(r'(?:[1-9]|1[0-2]):[0-5]\d [AP]M', time_text):
            raise ValueError('Invalid displayed time')
        time = datetime.strptime(time_text, '%I:%M %p').time()
        identity = int(identity)
        if (previous_id is not None and identity <= previous_id) or (previous_time is not None and time <= previous_time):
            raise ValueError('Duplicate or unordered result')
        previous_id, previous_time = identity, time
        if multiplier not in {'1', '3', '4', '5', '10'}:
            raise ValueError('Unknown Bonus multiplier')
        values = [n.text_content().strip() for n in nodes(row, 'keno-results_number')]
        if len(values) != 20 or any(not re.fullmatch(r'[1-9]\d?', v) for v in values):
            raise ValueError('Expected twenty drawn numbers')
        numbers = list(map(int, values))
        if len(set(numbers)) != 20 or any(n > 80 for n in numbers):
            raise ValueError('Duplicate or out-of-range number')
        result.append({'gameNumber': identity, 'drawDate': requested_date.isoformat(),
                       'displayTime': time_text, 'sourceTimezone': None,
                       'numbers': numbers, 'bonusMultiplier': int(multiplier)})
    return {'sourceUrl': SOURCE, 'game': 'Keno', 'results': result,
            'coverage': 'Observed date-search results only; local display times have no inferred timezone or UTC instant.'}
