"""Strict Missouri public report parsing; no publication or ticket identity inference."""
from datetime import date, datetime
from lxml import html
from missouri_scratch_catalog import integer, one, plain

MM_MATCHES = [
    '5 White balls & Mega Ball', '5 White balls',
    '4 White balls & Mega Ball', '4 White balls',
    '3 White balls & Mega Ball', '3 White balls',
    '2 White balls & Mega Ball', '1 White ball & Mega Ball',
    '0 White balls & Mega Ball',
]


def parse_mega_millions(raw, expected_date):
    """Retain source ranges, reconcile reported counts, and require dated full HTML.

    This is a published source snapshot, not a claim that settlement is final.
    The caller must separately select eligible dates and enforce continuity.
    """
    expected = date.fromisoformat(expected_date)
    closing = b'</html>' if isinstance(raw, bytes) else '</html>'
    if closing not in raw.lower():
        raise ValueError('Incomplete report document')
    tree = html.fromstring(raw)
    block = one(tree.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," block-megamillions-prizes-paid ")]'), 'Mega Millions report')
    heading = plain(one(block.xpath('./div[@class="content"]/div[@class="h1 text-center"]'), 'draw date'))
    try:
        observed = datetime.strptime(heading, '%A, %b %d, %Y').date()
    except ValueError as error:
        raise ValueError('Invalid draw date') from error
    if observed != expected or heading.split(',')[0] != observed.strftime('%A'):
        raise ValueError('Draw date identity mismatch')
    table = one(block.xpath('.//table'), 'prize table')
    if [plain(n) for n in table.xpath('./thead/tr/th')] != ['Numbers Matched', 'Number of MO Prizes', 'Prize amount']:
        raise ValueError('Changed prize columns')
    rows = [[plain(n) for n in r.xpath('./td')] for r in table.xpath('./tbody/tr')]
    if len(rows) != 11:
        raise ValueError('Incomplete or extra prize rows')
    tiers = []
    for index, (row, match) in enumerate(zip(rows[:9], MM_MATCHES)):
        if len(row) != 3 or row[0] != match:
            raise ValueError('Changed tier identity')
        label = row[2]
        if index == 0:
            if label != 'Jackpot':
                raise ValueError('Changed jackpot label')
        else:
            parts = label.split('-')
            if len(parts) != 2:
                raise ValueError('Expected literal prize range')
            low, high = [integer(p, money=True) for p in parts]
            if low <= 0 or high <= low:
                raise ValueError('Invalid prize range')
        tiers.append(dict(matchLabel=match, sourcePrizeCount=integer(row[1]),
                          prizeLabel=label, cashPrize=None))
    total = rows[9]
    if len(total) != 5 or total[0] != 'Grand Total MO Winners:' or total[2] != 'Grand Total Won:' or total[4]:
        raise ValueError('Changed report totals')
    count, payout = integer(total[1]), integer(total[3], money=True)
    if sum(t['sourcePrizeCount'] for t in tiers) != count:
        raise ValueError('Tier count differs from source total')
    # With no jackpot winner, the published payout must lie within source ranges.
    # Do not manufacture a multiplier distribution or a per-tier payout.
    if tiers[0]['sourcePrizeCount'] == 0:
        bounds = [0, 0]
        for tier in tiers[1:]:
            for i, p in enumerate(tier['prizeLabel'].split('-')):
                bounds[i] += integer(p, money=True) * tier['sourcePrizeCount']
        if not bounds[0] <= payout <= bounds[1]:
            raise ValueError('Reported payout outside prize bounds')
    if len(rows[10]) != 1 or not rows[10][0].startswith('Location(s) of Jackpot Winner(s):'):
        raise ValueError('Missing report trailer')
    return dict(game='Mega Millions', drawDate=expected_date, tiers=tiers,
                sourceWinnerCount=count, sourcePayoutDollars=payout,
                distinctTicketCount=None, finalityVerified=False,
                countUnit='Source Number of MO Prizes; not verified distinct tickets or people',
                coverage='Missouri published draw report. Prize ranges are retained; multiplier splits, claim dates and retailer locations are not inferred.')


def _dated_table(raw, expected_date, block_class, headers):
    expected = date.fromisoformat(expected_date)
    closing = b'</html>' if isinstance(raw, bytes) else '</html>'
    if closing not in raw.lower():
        raise ValueError('Incomplete report document')
    tree = html.fromstring(raw)
    block = one(tree.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," '+block_class+' ")]'), 'dated report')
    heading = plain(one(block.xpath('./div[@class="content"]/div[@class="h1 text-center"]'), 'draw date'))
    try:
        observed = datetime.strptime(heading, '%A, %b %d, %Y').date()
    except ValueError as error:
        raise ValueError('Invalid draw date') from error
    if observed != expected or heading.split(',')[0] != observed.strftime('%A'):
        raise ValueError('Draw date identity mismatch')
    table = one(block.xpath('.//table'), 'prize table')
    if [plain(n) for n in table.xpath('./thead/tr/th')] != headers:
        raise ValueError('Changed prize columns')
    return [[plain(n) for n in r.xpath('./td')] for r in table.xpath('./tbody/tr')]


def _fixed_tiers(rows, matches):
    if len(rows) != len(matches):
        raise ValueError('Incomplete or extra tiers')
    tiers = []
    for index, (row, match) in enumerate(zip(rows, matches)):
        if len(row) != 3 or row[0] != match:
            raise ValueError('Changed tier identity')
        count, amount = integer(row[1]), integer(row[2], money=True)
        if amount == 0 and (index != 0 or count != 0):
            raise ValueError('Invalid zero prize')
        tiers.append(dict(matchLabel=match, sourcePrizeCount=count,
                          prizeLabel=row[2], sourceAmount=amount, cashPrize=None))
    return tiers


def _fixed_report(game, expected_date, tiers, count, payout):
    if sum(t['sourcePrizeCount'] for t in tiers) != count:
        raise ValueError('Tier count differs from source total')
    if sum(t['sourceAmount'] * t['sourcePrizeCount'] for t in tiers) != payout:
        raise ValueError('Tier amounts differ from source payout')
    return dict(game=game, drawDate=expected_date, tiers=tiers,
                sourceWinnerCount=count, sourcePayoutDollars=payout,
                distinctTicketCount=None, finalityVerified=False,
                countUnit='Source Number of MO Prizes; not verified distinct tickets or people',
                coverage='Missouri published draw report. Source amounts are retained literally; a zero top-tier label with no winners does not establish a zero jackpot. No cash-option, claim-date or retailer inference.')


def parse_powerball_xo(raw, expected_date):
    rows = _dated_table(raw, expected_date, 'block-powerball-prizes-paid',
                        ['Teams Matched', 'Number of MO Prizes', 'Prize amount'])
    if len(rows) != 7:
        raise ValueError('Incomplete or extra Powerball Xs & Os rows')
    tiers = _fixed_tiers(rows[:5], [f'{n} Teams' for n in range(8, 3, -1)])
    if len(rows[5]) != 3 or rows[5][0] != 'Total:':
        raise ValueError('Changed source total')
    if len(rows[6]) != 1 or not rows[6][0].startswith('Location(s) of Jackpot Winner(s):'):
        raise ValueError('Missing report trailer')
    return _fixed_report('Powerball Xs & Os', expected_date, tiers,
                         integer(rows[5][1]), integer(rows[5][2], money=True))


def parse_show_me_cash(raw, expected_date):
    import re
    rows = _dated_table(raw, expected_date, 'block-show-me-cash-prizes-paid',
                        ['Numbers Matched', 'Number of MO Prizes', 'Prize amount'])
    if len(rows) != 5 or len(rows[4]) != 1:
        raise ValueError('Incomplete or extra Show Me Cash rows')
    tiers = _fixed_tiers(rows[:4], [f'Match {n} of 5' for n in range(5, 1, -1)])
    total = re.fullmatch(r'Total Winners: ([\d,]+) Total Won: (\$[\d,]+)', rows[4][0])
    if not total:
        raise ValueError('Changed source total')
    return _fixed_report('Show Me Cash', expected_date, tiers,
                         integer(total[1]), integer(total[2], money=True))


PB_MATCHES = [m.replace('Mega Ball', 'Powerball') for m in MM_MATCHES]


def parse_powerball(raw, expected_date):
    import re
    expected = date.fromisoformat(expected_date)
    closing = b'</html>' if isinstance(raw, bytes) else '</html>'
    if closing not in raw.lower():
        raise ValueError('Incomplete report document')
    tree = html.fromstring(raw)
    block = one(tree.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," block-powerball-prizes-paid ")]'), 'Powerball report')
    for tag, suffix in [('div', 'Main Drawing'), ('h2', 'Double Play Drawing')]:
        heading = plain(one(block.xpath('./div[@class="content"]/'+tag+'[@class="h1 text-center"]'), suffix))
        if heading != expected.strftime('%A, %b %d, %Y') + ' - ' + suffix:
            raise ValueError('Draw date identity mismatch')
    pp = plain(one(block.xpath('.//div[@class="num-list__pp"]'), 'Power Play multiplier'))
    multiplier = re.fullmatch(r'PP: (2|3|4|5|10)X', pp)
    if not multiplier:
        raise ValueError('Invalid Power Play multiplier')
    multiplier = int(multiplier[1])
    tables = block.xpath('.//table')
    if len(tables) != 2:
        raise ValueError('Expected main and Double Play tables')
    headers = [[plain(n) for n in t.xpath('./thead/tr/th')] for t in tables]
    if headers != [['Numbers Matched', 'Number of MO Prizes', 'Prize amount', 'Number of MO Power Play Prizes', 'Power Play Prize Amount'], ['Numbers Matched', 'Number of MO Prizes', 'Prize Amount']]:
        raise ValueError('Changed Powerball columns')
    main, double = [[[plain(n) for n in r.xpath('./td')] for r in t.xpath('./tbody/tr')] for t in tables]
    if len(main) != 13 or len(double) != 11:
        raise ValueError('Incomplete or extra Powerball rows')
    base, power = [], []
    for i, (row, match) in enumerate(zip(main[:9], PB_MATCHES)):
        if len(row) != 5 or row[0] != match:
            raise ValueError('Changed main tier identity')
        count = integer(row[1])
        if i == 0:
            if row[2:] != ['Jackpot', '-', '-']:
                raise ValueError('Changed jackpot/unavailable Power Play cells')
            amount, pcount, pamount = None, None, None
        else:
            amount, pcount, pamount = integer(row[2], True), integer(row[3]), integer(row[4], True)
            if amount <= 0 or pamount != (2000000 if i == 1 else amount * multiplier):
                raise ValueError('Inconsistent Power Play amount')
        base.append(dict(matchLabel=match, sourcePrizeCount=count, prizeLabel=row[2], sourceAmount=amount, cashPrize=None))
        power.append(dict(matchLabel=match, sourcePrizeCount=pcount, prizeLabel=row[4], sourceAmount=pamount, cashPrize=None))
    totals = []
    for row, label, won in zip(main[9:12], ['Total MO Winners (without Power Play):', 'Total MO Winners (with Power Play):', 'Grand Total MO Winners:'], ['Total Won:', 'Total Won:', 'Grand Total Won:']):
        if len(row) != 5 or row[0] != label or row[2] != won or row[4]:
            raise ValueError('Changed Powerball totals')
        totals.append((integer(row[1]), integer(row[3], True)))
    if sum(t['sourcePrizeCount'] for t in base) != totals[0][0] or sum(t['sourcePrizeCount'] or 0 for t in power) != totals[1][0]:
        raise ValueError('Powerball count mismatch')
    if tuple(a+b for a,b in zip(totals[0],totals[1])) != totals[2]:
        raise ValueError('Powerball combined total mismatch')
    base_payout = sum(t['sourcePrizeCount'] * t['sourceAmount'] for t in base[1:])
    if (base[0]['sourcePrizeCount'] == 0 and base_payout != totals[0][1]) or base_payout > totals[0][1]:
        raise ValueError('Powerball base payout mismatch')
    if sum(t['sourcePrizeCount'] * t['sourceAmount'] for t in power[1:]) != totals[1][1]:
        raise ValueError('Power Play payout mismatch')
    if len(main[12]) != 1 or not main[12][0].startswith('Location(s) of Jackpot Winner(s):'):
        raise ValueError('Missing main report trailer')
    dt = _fixed_tiers(double[:9], PB_MATCHES)
    if len(double[9]) != 3 or double[9][0] != 'Total MO Winners:' or double[9][2] or len(double[10]) != 3 or double[10][:2] != ['Total WON:', '']:
        raise ValueError('Changed Double Play totals')
    d = _fixed_report('Powerball Double Play', expected_date, dt, integer(double[9][1]), integer(double[10][2], True))
    variants = []
    for name, tiers, total in zip(['Base without Power Play', 'With Power Play'], [base, power], totals[:2]):
        variants.append(dict(variant=name, tiers=tiers, sourceWinnerCount=total[0], sourcePayoutDollars=total[1]))
    variants.append(dict(variant='Double Play', tiers=d['tiers'], sourceWinnerCount=d['sourceWinnerCount'], sourcePayoutDollars=d['sourcePayoutDollars']))
    return dict(game='Powerball', drawDate=expected_date, powerPlayMultiplier=multiplier,
                variants=variants, mainSourceWinnerCount=totals[2][0], mainSourcePayoutDollars=totals[2][1],
                distinctTicketCount=None, finalityVerified=False,
                coverage='Missouri source prizes. Main total combines without/with Power Play columns; Double Play is separate. No unique tickets or people across variants; unavailable jackpot Power Play cells remain null. Literal prizes do not establish cash options or claim dates.')


MO_MILLIONS_MATCHES = ['6 White Balls', '5 White Balls & Bulls-Eye', '5 White Balls',
                       '4 White Balls & Bulls-Eye', '4 White Balls',
                       '3 White Balls & Bulls-Eye', '3 White Balls', '2 White Balls & Bulls-Eye']
CASH_POP_SESSIONS = {1: 'Early Bird', 2: 'Late Morning', 3: 'Matinee', 4: 'Prime Time', 5: 'Night Owl'}
CASH_POP_AMOUNTS = [2500, 1250, 1000, 500, 250, 200, 150, 125, 100, 75, 70, 50,
                    40, 35, 30, 25, 20, 15, 14, 10, 7, 5]


def _report_block(raw, block_class):
    closing = b'</html>' if isinstance(raw, bytes) else '</html>'
    if closing not in raw.lower():
        raise ValueError('Incomplete report document')
    tree = html.fromstring(raw)
    return one(tree.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," '+block_class+' ")]'), 'report block')


def parse_mo_millions(raw, expected_date):
    expected = date.fromisoformat(expected_date)
    block = _report_block(raw, 'block-powerball-prizes-paid')
    headings = [plain(n) for n in block.xpath('./div[@class="content"]/div[@class="h1 text-center"]')]
    if headings != [expected.strftime('%A, %b %d, %Y')+' - '+s for s in ['Main Drawing', 'Double Play Drawing']]:
        raise ValueError('MO Millions variant date identity mismatch')
    tables = block.xpath('.//table')
    if len(tables) != 2:
        raise ValueError('Expected both MO Millions variants')
    variants = []
    for name, table in zip(['Main', 'Double Play'], tables):
        if [plain(n) for n in table.xpath('./thead/tr/th')] != ['Numbers Matched', 'Number of MO Prizes', 'Prize amount', '']:
            raise ValueError('Changed MO Millions columns')
        rows = [[plain(n) for n in r.xpath('./td')] for r in table.xpath('./tbody/tr')]
        if len(rows) != 9 or any(len(r) != 4 or r[3] for r in rows[:8]):
            raise ValueError('Incomplete or extra MO Millions tiers')
        tiers = _fixed_tiers([r[:3] for r in rows[:8]], MO_MILLIONS_MATCHES)
        total = rows[8]
        if len(total) != 4 or total[0] != 'Grand Total Winners:' or total[2] != 'Grand Total Won:':
            raise ValueError('Changed MO Millions total')
        report = _fixed_report('MO Millions', expected_date, tiers, integer(total[1]), integer(total[3], True))
        variants.append(dict(variant=name, tiers=tiers, sourceWinnerCount=report['sourceWinnerCount'], sourcePayoutDollars=report['sourcePayoutDollars']))
    return dict(game='MO Millions', drawDate=expected_date, variants=variants,
                distinctTicketCount=None, finalityVerified=False,
                coverage='Missouri source prizes. Bulls-Eye matches retain their own rows; Double Play totals remain separate. Printed zero top prize with no winners is not a zero jackpot assertion. No unique tickets/people across variants, cash-option or claim-date inference. EZ Match is not included.')


def parse_cash_pop(raw, expected_date, session):
    import re
    if type(session) is not int or session not in CASH_POP_SESSIONS:
        raise ValueError('Unknown Cash Pop session')
    expected = date.fromisoformat(expected_date)
    block = _report_block(raw, 'block-cashpop-prizes-paid')
    heading = plain(one(block.xpath('./div[@class="content"]/div[@class="h1 text-center"]'), 'Cash Pop date/session'))
    if heading != expected.strftime('%A, %b %d, %Y')+', '+CASH_POP_SESSIONS[session]:
        raise ValueError('Cash Pop date/session mismatch')
    table = one(block.xpath('.//table'), 'Cash Pop prize table')
    if [plain(n) for n in table.xpath('./thead/tr/th')] != ['Number of Prizes', 'Prize Amount']:
        raise ValueError('Changed Cash Pop columns')
    rows = [[plain(n) for n in r.xpath('./td')] for r in table.xpath('./tbody/tr')]
    if len(rows) != len(CASH_POP_AMOUNTS)+1:
        raise ValueError('Incomplete or extra Cash Pop tiers')
    tiers = []
    for row, amount in zip(rows[:-1], CASH_POP_AMOUNTS):
        if len(row) != 2 or integer(row[1], True) != amount:
            raise ValueError('Changed Cash Pop prize tiers')
        tiers.append(dict(matchLabel=None, sourcePrizeCount=integer(row[0]), prizeLabel=row[1], sourceAmount=amount, cashPrize=None))
    total = re.fullmatch(r'Total Winners: ([\d,]+) Total Won: (\$[\d,]+)', rows[-1][0]) if len(rows[-1]) == 1 else None
    if not total:
        raise ValueError('Changed Cash Pop total')
    report = _fixed_report('Cash Pop', expected_date, tiers, integer(total[1]), integer(total[2], True))
    report.update(sessionId=session, sessionLabel=CASH_POP_SESSIONS[session],
                  coverage='Missouri source prizes by prize amount for the named drawing session. No wager grouping, exact draw timestamp, unique ticket/person or claim-date inference.')
    return report


PICK_MATCHES = {
    3: ['Straight*', 'Box 3-way', 'Box 6-way', 'Front 2', 'Back 2'],
    4: ['Straight*', 'Box 4-way', 'Box 6-way', 'Box 12-way', 'Box 24-way',
        'Front 3', 'Back 3', 'Front 2', 'Mid 2', 'Back 2'],
}


def _money_cents(value):
    import re
    from decimal import Decimal
    if not re.fullmatch(r'\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d{1,2})?', value):
        raise ValueError('Invalid dollar amount')
    return int(Decimal(value[1:].replace(',', '')) * 100)


def parse_pick(raw, expected_date, game, session):
    import re
    if type(game) is not int or game not in PICK_MATCHES or session not in ('Midday', 'Evening'):
        raise ValueError('Unknown Pick game/session')
    expected = date.fromisoformat(expected_date)
    block = _report_block(raw, f'block-pick{game}-prizes-paid')
    heading = plain(one(block.xpath('./div[@class="content"]/div[@class="h1 text-center"]'), 'Pick date/session'))
    if heading != expected.strftime('%A, %b %d, %Y')+' - '+session:
        raise ValueError('Pick date/session mismatch')
    table = one(block.xpath('.//table'), 'Pick prize table')
    heads = table.xpath('./thead/tr')
    amount_header = 'Prize amount' if game == 3 else 'Prize Amount'
    if len(heads) != 2 or [plain(n) for n in heads[0].xpath('./th')] != [f'Pick {game}', f'Pick {game} + Wild ball'] or [n.get('colspan') for n in heads[0].xpath('./th')] != ['3', '2'] or [plain(n) for n in heads[1].xpath('./th')] != ['Numbers Matched', 'Number of MO Prizes', amount_header, 'Number of MO Prizes', amount_header]:
        raise ValueError('Changed Pick variant columns')
    rows = [[plain(n) for n in r.xpath('./td')] for r in table.xpath('./tbody/tr')]
    matches = PICK_MATCHES[game]
    if len(rows) != len(matches)+2 or rows[-2] != ['(Based on $.50 Plays)']:
        raise ValueError('Changed Pick tiers or play basis')
    variants = [dict(variant=f'Pick {game}', tiers=[]), dict(variant=f'Pick {game} + Wild ball', tiers=[])]
    for row, match in zip(rows[:-2], matches):
        if len(row) != 5 or row[0] != match:
            raise ValueError('Changed Pick match identity')
        for v, offset in zip(variants, [1, 3]):
            count, amount = integer(row[offset]), _money_cents(row[offset+1])
            if amount <= 0:
                raise ValueError('Invalid Pick prize')
            v['tiers'].append(dict(matchLabel=match, sourcePrizeCount=count,
                                   prizeLabel=row[offset+1], sourceAmountCents=amount, cashPrize=None))
    total = re.fullmatch(r'Total Winners: ([\d,]+) Total Won: (\$[\d,.]+)', rows[-1][0]) if len(rows[-1]) == 1 else None
    if not total:
        raise ValueError('Changed Pick source total')
    count, cents = integer(total[1]), _money_cents(total[2])
    if sum(t['sourcePrizeCount'] for v in variants for t in v['tiers']) != count or sum(t['sourcePrizeCount']*t['sourceAmountCents'] for v in variants for t in v['tiers']) != cents:
        raise ValueError('Pick source totals mismatch')
    return dict(game=f'Pick {game}', drawDate=expected_date, sessionLabel=session,
                variants=variants, sourceWinnerCount=count, sourcePayoutCents=cents,
                sourcePayoutLabel=total[2], playBasisCents=50, distinctTicketCount=None,
                finalityVerified=False,
                coverage='Missouri published prizes based on $.50 plays. Base and Wild ball columns remain separate; combined source total is not verified distinct tickets or people. Straight asterisk retained literally. No exact draw timestamp, claim-date or retailer inference.')
