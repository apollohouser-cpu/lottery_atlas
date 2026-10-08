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


def parse_pick_summary(raw, game, source_url, today=None):
    """Read the combined summary; payout schedules are not tier winner reports."""
    if game not in ('Pick 3', 'Pick 4'):
        raise ValueError('Unsupported Pick game')
    size = int(game[-1])
    if not re.fullmatch(r'https://nclottery\.com/Pick'+str(size)+r'-Draw\?dn=[1-9]\d*', source_url):
        raise ValueError('Wrong Pick report source')
    if b'</html>' not in raw.lower():
        raise ValueError('Incomplete Pick document')
    root = html.fromstring(raw)
    mains = root.xpath('//main')
    if len(mains) != 1: raise ValueError('Missing or duplicate Pick report')
    main = mains[0]
    prefix = 'ctl00_MainContent_PayoutPick'+str(size)+'_PayoutRepeater_ctl00_'

    def node(suffix):
        found = main.xpath('.//span[@id=$id]', id=prefix+suffix)
        if len(found) != 1: raise ValueError('Missing or duplicate Pick field: '+suffix)
        return found[0]

    date_node = node('lblDrawDate')
    label = text(date_node)
    date = datetime.strptime(label, '%A %b %d, %Y').date()
    if label.split()[0] != date.strftime('%A'):
        raise ValueError('Mismatched Pick weekday')
    if date > (today or datetime.now(timezone.utc).date()):
        raise ValueError('Future Pick drawing')
    sessions = date_node.xpath('.//svg/@aria-label')
    if len(sessions) != 1 or sessions[0] not in ('Daytime Draw', 'Evening Draw'):
        raise ValueError('Missing or unknown Pick session')
    session = sessions[0].removesuffix(' Draw')
    balls = main.xpath('.//span[starts-with(@id,$prefix)]', prefix=prefix+'lblBall')
    if len(balls) != size: raise ValueError('Wrong Pick digit count')
    digits = [text(node('lblBall'+str(i))) for i in range(1,size+1)]
    fireball = text(node('lblFireball'))
    if any(not re.fullmatch('[0-9]', value) for value in digits+[fireball]):
        raise ValueError('Invalid Pick digit')
    if text(node('lblWinningsLabel')) != 'Total Combined Winnings':
        raise ValueError('Changed Pick summary definition')
    summary = text(node('lblWinnings'))
    match = re.fullmatch(r'(.+) winners won a total of (.+)', summary)
    if not match: raise ValueError('Changed Pick summary format')
    winners, payout_label = integer(match[1]), match[2]
    payout = money_cents(payout_label)
    if (winners == 0) != (payout == 0):
        raise ValueError('Inconsistent Pick zero winners/payout')
    return dict(id=f'pick-{size}-{date.isoformat()}-{session.lower()}',
        game=game, session=session, drawDate=date.isoformat(),
        reportType='combined-summary', winningDigits=digits, fireball=fireball,
        reportedWinners=winners, reportedPayoutLabel=payout_label,
        reportedPayoutCents=payout, sourceSummaryLabel=summary,
        sourceUrl=source_url,
        coverage='Official Total Combined Winnings summary only. The source payout schedules do not provide tier winner counts. No base/Fireball split, distinct-person total, retailer claims or map positions.')


def parse_pick_reports(documents, game, today=None):
    """Validate every fetched detail before selecting two per day/evening group."""
    groups = {'Daytime': [], 'Evening': []}
    seen = set()
    for url, raw in documents:
        report = parse_pick_summary(raw, game, url, today=today)
        if report['id'] in seen: raise ValueError('Duplicate Pick date/session')
        seen.add(report['id'])
        groups[report['session']].append(report)
    if any(len(rows) < 2 for rows in groups.values()):
        raise ValueError('Two reports required for each Pick session')
    return [r for rows in groups.values()
            for r in sorted(rows, key=lambda r:r['drawDate'], reverse=True)[:2]]
