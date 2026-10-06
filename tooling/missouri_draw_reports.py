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
