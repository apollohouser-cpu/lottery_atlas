"""Literal three-column prize references, separate from dated payout reports."""
import re
from tooling.connecticut_keno_prizes import Tables

CONFIG = {
    'cash5': [('Cash5 without Kicker', 3), ('Cash5 with Kicker', 4)],
    'mfl': [('Millionaire for Life reference prizes', 9)],
    'lotto': [('Lotto reference prizes', 4)],
    'megamillions': [('Mega Millions base prizes', 9)],
}
BASIS = {
    'cash5': 'Advertised reference prizes may be reduced. Kicker figures here are combined advertised prizes, not the separate Kicker amounts in dated reports.',
    'mfl': 'Annual life-prize labels are not cash amounts or lifetime totals. Payment conditions and potential reductions apply; see rule qualifications.',
    'lotto': 'Starred prizes depend on the prize pool and winners and can differ from advertised reference amounts.',
    'megamillions': 'Non-jackpot base prizes require the multiplier assigned to the individual play. These are not actual payouts or winning-ticket counts.',
}


def parse(html, game):
    parser = Tables(); parser.feed(html)
    tables = [t for t in parser.tables if t['rows'] and t['rows'][0] in
              [['Match', 'Prize', 'Odds'], ['Match', 'Base Prize*', 'Odds']]]
    config = CONFIG[game]
    if len(tables) != len(config):
        raise ValueError('Missing or additional reference tables')
    for table, (title, count) in zip(tables, config):
        if len(table['rows']) != count + 1:
            raise ValueError('Changed reference tier count')
        seen = set()
        for row in table['rows'][1:]:
            if (len(row) != 3 or not row[0] or row[0] in seen or
                    not (row[1].startswith('$') or row[1].startswith('JACKPOT')) or
                    not re.fullmatch(r'1 in [\d,]+', row[2])):
                raise ValueError('Invalid reference row')
            seen.add(row[0])
        table.update(title=title, basis=BASIS[game])
    return tables
