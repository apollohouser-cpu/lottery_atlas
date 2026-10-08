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
        report = parse_pick_report(raw, game, url, today=today)
        if report['id'] in seen: raise ValueError('Duplicate Pick date/session')
        seen.add(report['id'])
        groups[report['session']].append(report)
    if any(len(rows) < 2 for rows in groups.values()):
        raise ValueError('Two reports required for each Pick session')
    return [r for rows in groups.values()
            for r in sorted(rows, key=lambda r:r['drawDate'], reverse=True)[:2]]


def schedule_text(node):
    # Separate inline labels, combinations and <br> content without joining digits.
    return ' '.join(' '.join(node.itertext()).split())


def schedule_grid(table):
    """Expand explicit rowspans within each tbody; never infer missing cells."""
    rows = []
    for body in table.xpath('./tbody'):
        pending = {}
        for tr in body.xpath('./tr'):
            row = [None] * 4
            for column, (value, remaining) in list(pending.items()):
                row[column] = value
                if remaining == 1: del pending[column]
                else: pending[column] = (value, remaining - 1)
            column = 0
            for cell in tr.xpath('./td'):
                while column < 4 and row[column] is not None: column += 1
                if column == 4 or cell.get('colspan', '1') != '1':
                    raise ValueError('Changed Pick schedule width')
                span = cell.get('rowspan', '1')
                if not re.fullmatch('[1-9][0-9]*', span) or int(span) > 14:
                    raise ValueError('Invalid Pick schedule rowspan')
                value = schedule_text(cell)
                row[column] = value
                if int(span) > 1: pending[column] = (value, int(span)-1)
                column += 1
            if any(value is None for value in row):
                raise ValueError('Incomplete Pick schedule row')
            rows.append(row)
        if pending: raise ValueError('Pick rowspan crosses table body')
    return rows


def parse_pick_schedules(raw, game):
    if game not in ('Pick 3', 'Pick 4') or b'</html>' not in raw.lower():
        raise ValueError('Invalid Pick schedule document')
    tables = html.fromstring(raw).xpath('//main//table[contains(concat(" ",normalize-space(@class)," ")," payout_results ")]')
    expected_titles = [game+' Prizes', 'Fireball Prizes']
    if len(tables) != 2 or [text(t.xpath('./caption')[0]) if len(t.xpath('./caption')) == 1 else '' for t in tables] != expected_titles:
        raise ValueError('Missing/changed Pick schedule captions')
    result = []
    ways = ['3-Way', '6-Way'] if game == 'Pick 3' else ['4-Way', '6-Way', '12-Way', '24-Way']
    amount = r'\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d{2})?'
    payout_patterns = [amount, amount+r' Play '+amount,
                       r'Exact\+Any '+amount+r' Any '+amount, 'N/A']
    for index, table in enumerate(tables):
        headers = table.xpath('./thead/tr')
        payout_header = 'Payout' if index == 0 else 'Payout / Win'
        if len(headers) != 2 or [text(c) for c in headers[0].xpath('./th')] != ['Play Type','Match',payout_header] or [text(c) for c in headers[1].xpath('./td')] != ['', '', '50¢ Base Play', '$1 Base Play']:
            raise ValueError('Changed Pick schedule columns')
        if headers[0].xpath('./th')[-1].get('colspan') != '2':
            raise ValueError('Changed Pick payout column span')
        grid = schedule_grid(table)
        expected_plays = ['EXACT','ANY','50/50','COMBO','PAIR'] if index == 0 else ['EXACT']+[play for play in ['ANY','50/50','COMBO'] for _ in ways]+['PAIR']
        if [row[0] for row in grid] != expected_plays:
            raise ValueError('Missing/changed Pick schedule play types')
        if index == 1 and [row[1] for row in grid] != ['']+ways*3+['Front | Back']:
            raise ValueError('Changed Fireball match groups')
        if index == 0 and any(not row[1] for row in grid):
            raise ValueError('Missing base Pick match label')
        for row in grid:
            for value in row[2:]:
                if not any(re.fullmatch(pattern, value) for pattern in payout_patterns):
                    raise ValueError('Invalid literal Pick payout label')
        notes = [schedule_text(cell) for cell in table.xpath('./tfoot/tr/td') if schedule_text(cell)]
        if index == 1 and notes != ['Fireball wins are dependent on your numbers chosen and play type.']:
            raise ValueError('Missing/changed Fireball qualification')
        result.append(dict(title=expected_titles[index], payoutHeading=payout_header,
            wagerLabels=['50¢ Base Play','$1 Base Play'],
            rows=[dict(playType=r[0],matchLabel=r[1],payoutLabels=r[2:]) for r in grid],
            notes=notes,
            coverage='Literal payout schedule, not observed tier winner counts or total winnings.'))
    return result


def parse_pick_report(raw, game, source_url, today=None):
    report = parse_pick_summary(raw, game, source_url, today=today)
    report['payoutSchedules'] = parse_pick_schedules(raw, game)
    return report
