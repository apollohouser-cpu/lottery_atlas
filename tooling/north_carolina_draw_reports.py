"""Strict NC reports. Session totals remain distinct from tier winner tables."""
from datetime import datetime, timezone
from decimal import Decimal
import re
from lxml import html

CASH_POP_URL = 'https://nclottery.com/cash-pop'
CASH_POP_SESSIONS = {
    'Morning Buzz': '9:00 AM',
    'Lunch Rush': '1:00 PM',
    'Clock Out Cash': '5:00 PM',
    'Primetime Pop': '8:00 PM',
    'Midnight Money': '11:59 PM',
}


def text(node):
    return ' '.join(node.text_content().split())


def integer(value):
    if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)', value):
        raise ValueError('Invalid winner count or Pop')
    return int(value.replace(',', ''))


def money_cents(value):
    if not re.fullmatch(r'\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d{2})?', value):
        raise ValueError('Invalid reported payout')
    return int(Decimal(value[1:].replace(',', '')) * 100)


def field(row, suffix):
    found = row.xpath('.//span[substring(@id,string-length(@id)-string-length($suffix)+1)=$suffix]', suffix=suffix)
    if len(found) != 1: raise ValueError('Missing or duplicate report field: '+suffix)
    return text(found[0])


def parse_cash_pop(raw, today=None):
    if b'</html>' not in raw.lower(): raise ValueError('Incomplete Cash Pop document')
    root = html.fromstring(raw)
    tables = root.xpath('//main//table[contains(concat(" ",normalize-space(@class)," ")," past_draws ")]')
    if len(tables) != 1: raise ValueError('Missing or duplicate Cash Pop history')
    table = tables[0]
    if [text(t) for t in table.xpath('./thead/tr/th')] != ['Date','Drawing','Pop','Winners','Payout','Watch*']:
        raise ValueError('Changed Cash Pop columns')
    today = today or datetime.now(timezone.utc).date()
    groups = {name:[] for name in CASH_POP_SESSIONS}
    seen = set()
    for row in table.xpath('./tbody/tr'):
        if len(row.xpath('./td')) != 6: raise ValueError('Incomplete Cash Pop row')
        name, clock = field(row,'lblSlotName'), field(row,'lblSlotTime')
        if name not in groups or CASH_POP_SESSIONS[name] != clock:
            raise ValueError('Unknown/mismatched Cash Pop session')
        date = datetime.strptime(field(row,'lblDrawDate'),'%Y, %b %d').date()
        if date > today: raise ValueError('Future Cash Pop date')
        key = (date.isoformat(), name)
        if key in seen: raise ValueError('Duplicate Cash Pop date/session')
        seen.add(key)
        pop = integer(field(row,'lblPop'))
        winners = integer(field(row,'lblTotalWinners'))
        payout_label = field(row,'lblTotalPayout'); payout = money_cents(payout_label)
        if not 1 <= pop <= 15: raise ValueError('Pop outside 1–15')
        if (winners == 0) != (payout == 0): raise ValueError('Inconsistent zero winners/payout')
        groups[name].append(dict(id='cash-pop-'+date.isoformat()+'-'+name.lower().replace(' ','-'),
            game='Cash Pop',session=name,sessionTimeLabel=clock,drawDate=date.isoformat(),
            reportType='session-summary',pop=pop,reportedWinners=winners,
            reportedPayoutLabel=payout_label,reportedPayoutCents=payout,
            sourceUrl=CASH_POP_URL+'#CashPopPast',
            coverage='Official aggregate session winners and payout only. No per-tier winner counts, distinct-person total, retailer claims or map positions. Watch is an animated drawing simulation.'))
    if any(len(rows)<2 for rows in groups.values()):
        raise ValueError('Two recent reports required for every Cash Pop session')
    # Validate all supplied rows before bounding the supported recent window.
    return [report for rows in groups.values()
            for report in sorted(rows,key=lambda r:r['drawDate'],reverse=True)[:2]]
