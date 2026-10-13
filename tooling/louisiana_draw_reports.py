"""Strict bounded Louisiana reports; never infer retailer joins or ticket totals."""
from datetime import date, datetime
from decimal import Decimal
import re
from zoneinfo import ZoneInfo
from lxml import html

GAMES = {'Lotto': ('lotto', 6, 42), 'Easy 5': ('easy-5', 5, 37)}
CENTRAL = ZoneInfo('America/Chicago')


def text(node):
    return ' '.join(node.text_content().split())


def one(nodes):
    if len(nodes) != 1:
        raise ValueError('Missing or duplicate source element')
    return nodes[0]


def count(value):
    if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)', value):
        raise ValueError('Invalid winner count')
    return int(value.replace(',', ''))


def money(value):
    if not re.fullmatch(r'\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d{2})?', value):
        raise ValueError('Invalid cash label')
    return int(Decimal(value[1:].replace(',', '')) * 100)


def source_time(value, today):
    match = re.fullmatch(r'Last Updated: (\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2} [AP]M) (CDT|CST)', value)
    if not match:
        raise ValueError('Invalid source timestamp')
    result = datetime.strptime(match[1], '%m/%d/%Y %I:%M:%S %p').replace(tzinfo=CENTRAL)
    if result.tzname() != match[2] or result.date() > today:
        raise ValueError('Invalid source timezone or future date')
    return result


def parse_local_reports(raw, game, *, today=None):
    """Validate every paired history row before selecting two recent reports."""
    today = today or datetime.now(CENTRAL).date()
    if game not in GAMES or b'</html>' not in raw.lower():
        raise ValueError('Unsupported game or incomplete HTML')
    slug, size, maximum = GAMES[game]
    root = html.fromstring(raw)
    if text(one(root.xpath('//h1'))) != game:
        raise ValueError('Wrong game page')
    main = one(root.xpath('//main'))
    table = one(main.xpath('.//table[@class="winning-numbers__table"]'))
    if [text(e) for e in table.xpath('./thead/tr/th')] != ['Draw Date', 'Winning Numbers', 'Jackpot']:
        raise ValueError('Changed history columns')
    rows = table.xpath('./tr | ./tbody/tr')
    for row in list(rows):
        if row.get('class') == 'winning-numbers__more':
            if text(row) != 'Load More' or len(row.xpath('./td/button[@data-winning-numbers-more]')) != 1:
                raise ValueError('Changed continuation control')
            rows.remove(row)
    if len(rows) < 4 or len(rows) % 2:
        raise ValueError('Incomplete date/report pairs')
    reports = []
    seen = set()
    for i in range(0, len(rows), 2):
        head, detail = rows[i:i+2]
        if len(head.xpath('./th')) != 1 or len(head.xpath('./td')) != 2:
            raise ValueError('Changed date row')
        stamp = one(head.xpath('./th/span[@id]'))
        draw = date.fromisoformat(stamp.get('id'))
        label = datetime.strptime(text(stamp), '%A, %B %d, %Y').date()
        if draw != label or text(stamp).split(',')[0] != draw.strftime('%A') or draw > today or draw in seen:
            raise ValueError('Invalid or duplicate draw date')
        if draw.weekday() not in (2, 5):
            raise ValueError('Unexpected drawing day')
        seen.add(draw)
        numbers = [text(n) for n in head.xpath('./td//ul[@aria-label="winning numbers"]/li')]
        if len(numbers) != size or any(not re.fullmatch(r'\d{2}', n) for n in numbers):
            raise ValueError('Changed winning numbers')
        if len(set(numbers)) != size or any(not 1 <= int(n) <= maximum for n in numbers):
            raise ValueError('Invalid winning numbers')
        jackpot = text(one(head.xpath(".//span[contains(concat(' ',normalize-space(@class),' '),' winning-numbers__jackpot__total ')]")))
        money(jackpot.removesuffix('(ticket purchased)').strip())
        toggle = one(head.xpath('.//disclosure-toggle'))
        region = one(detail.xpath('./td/div[@class="winning-numbers__detail"]'))
        if toggle.get('controls') != region.get('id') or toggle.get('key') != region.get('aria-labelledby'):
            raise ValueError('Mismatched report association')
        tiers_table = one(region.xpath('./table'))
        if text(one(tiers_table.xpath('./caption'))) != 'Winners in Louisiana':
            raise ValueError('Changed geographic unit')
        if [text(e) for e in tiers_table.xpath('./thead/tr/th')] != ['Winning Combinations', 'Winners', 'Prize']:
            raise ValueError('Changed tier columns')
        tier_rows = tiers_table.xpath('./tbody/tr')
        if len(tier_rows) != 4:
            raise ValueError('Missing or extra tiers')
        tiers = []
        for offset, row in enumerate(tier_rows):
            cells = row.xpath('./td')
            if len(cells) != 3:
                raise ValueError('Changed tier cells')
            matched = size - offset
            expected = f'{game} numbers: '+(f'1 through {matched}' if matched > 2 else '1 and 2')
            if text(cells[0]) != expected or len(cells[0].xpath('.//li')) != matched:
                raise ValueError('Changed match identity or symbols')
            prize = text(cells[2])
            if offset == 0:
                if prize != 'Jackpot': raise ValueError('Changed jackpot label')
            else:
                money(prize)
            tiers.append({'match': str(matched), 'sourceMatchLabel': expected,
                          'winners': count(text(cells[1])), 'prizeLabel': prize})
        updated = text(one(tiers_table.xpath('./tfoot/tr/td/p')))
        timestamp = source_time(updated, today)
        warnings = []
        if timestamp.date() < draw:
            warnings.append('The printed source update date precedes the draw date. Both dates are retained without correction.')
        reports.append({'game': game, 'session': 'Drawing', 'drawDate': draw.isoformat(),
                        'numbers': numbers, 'advertisedJackpot': jackpot, 'tiers': tiers,
                        'sourceUpdatedText': updated, 'sourceUpdatedAt': timestamp.isoformat(),
                        'sourceWarnings': warnings,
                        'sourceUrl': f'https://louisianalottery.com/draw-games/{slug}/#{draw.isoformat()}',
                        'coverage': 'Source-reported Louisiana winners by tier, not certified distinct tickets or people, complete claims, or retailer activity. Jackpot advertisement is not a paid total.'})
    reports.sort(key=lambda r: r['drawDate'], reverse=True)
    return reports[:2]


def parse_pick_reports(raw, game, *, today=None):
    """Dated play-type summaries only; payout schedules are a separate source."""
    today = today or datetime.now(CENTRAL).date()
    if game not in ('Pick 3', 'Pick 4', 'Pick 5') or b'</html>' not in raw.lower():
        raise ValueError('Unsupported Pick page or incomplete HTML')
    size = int(game[-1])
    root = html.fromstring(raw)
    if text(one(root.xpath('//h1'))) != game:
        raise ValueError('Wrong Pick page')
    main = one(root.xpath('//main'))
    table = one(main.xpath('.//table[@class="winning-numbers__table"]'))
    if [text(e) for e in table.xpath('./thead/tr/th')] != ['Draw Date', 'Winning Numbers']:
        raise ValueError('Changed Pick history columns')
    rows = table.xpath('./tr | ./tbody/tr')
    for row in list(rows):
        if row.get('class') == 'winning-numbers__more':
            if text(row) != 'Load More' or len(row.xpath('./td/button[@data-winning-numbers-more]')) != 1:
                raise ValueError('Changed continuation control')
            rows.remove(row)
    if len(rows) < 4 or len(rows) % 2:
        raise ValueError('Incomplete Pick pairs')
    reports, seen = [], set()
    expected_columns = ['Play Type', 'Statewide Total'] if size < 5 else ['Play Type', 'Statewide Winners', 'Statewide Total']
    labels = ['Straight', 'Box', 'Straight/Box', 'Combo'] if size < 5 else ['Straight', 'Box', 'Front 4', 'Back 4', 'Front 3', 'Back 3', 'Front 2', 'Back 2']
    for i in range(0, len(rows), 2):
        head, detail = rows[i:i+2]
        if len(head.xpath('./th')) != 1 or len(head.xpath('./td')) != 2:
            raise ValueError('Changed Pick date row')
        stamp = one(head.xpath('./th/span[@id]'))
        draw = date.fromisoformat(stamp.get('id'))
        label = datetime.strptime(text(stamp), '%A, %B %d, %Y').date()
        if draw != label or text(stamp).split(',')[0] != draw.strftime('%A') or draw > today or draw in seen:
            raise ValueError('Invalid or duplicate Pick date')
        seen.add(draw)
        digits = [text(n) for n in head.xpath('./td//ul[@aria-label="winning numbers"]/li')]
        if len(digits) != size or any(not re.fullmatch(r'[0-9]', n) for n in digits):
            raise ValueError('Invalid Pick digits')
        toggle = one(head.xpath('.//disclosure-toggle'))
        region = one(detail.xpath('./td/div[@class="winning-numbers__detail"]'))
        if toggle.get('controls') != region.get('id') or toggle.get('key') != region.get('aria-labelledby'):
            raise ValueError('Wrong Pick report association')
        summary = one(region.xpath('./table'))
        if [text(e) for e in summary.xpath('./thead/tr/th')] != expected_columns:
            raise ValueError('Changed Pick summary columns')
        data = summary.xpath('./tbody/tr')
        if len(data) != len(labels):
            raise ValueError('Missing or extra Pick play types')
        entries = []
        for row, expected in zip(data, labels):
            cells = row.xpath('./td')
            if len(cells) != len(expected_columns) or text(cells[0]) != expected:
                raise ValueError('Changed Pick play type or cells')
            amount = text(cells[-1])
            entry = {'playType': expected, 'statewideTotalLabel': amount, 'statewideTotalCents': money(amount)}
            if size == 5:
                entry['statewideWinners'] = count(text(cells[1]))
            entries.append(entry)
        updated = text(one(summary.xpath('./tfoot/tr/td/p')))
        timestamp = source_time(updated, today)
        warnings = []
        if timestamp.date() < draw:
            warnings.append('The printed source update date precedes the draw date. Both dates are retained without correction.')
        reports.append({'game': game, 'session': 'Daily', 'drawDate': draw.isoformat(),
                        'digits': digits, 'summaryColumns': expected_columns, 'playTypes': entries,
                        'sourceUpdatedText': updated, 'sourceUpdatedAt': timestamp.isoformat(),
                        'sourceWarnings': warnings,
                        'sourceUrl': f'https://louisianalottery.com/draw-games/pick-{size}/#{draw.isoformat()}',
                        'coverage': ('Play-type dollar totals only; no source winner counts. ' if size < 5 else 'Source statewide winners and dollar totals by play type. ')
                        + 'Not certified distinct tickets or people, net payments, complete claims or retailer activity. Payout schedules are separate from observed totals.'})
    reports.sort(key=lambda r: r['drawDate'], reverse=True)
    return reports[:2]


def parse_pick_schedule(raw, game):
    """Keep published schedule cells/spans and qualifications, never winner counts."""
    if game not in ('Pick 3', 'Pick 4', 'Pick 5') or b'</html>' not in raw.lower():
        raise ValueError('Unsupported Pick schedule')
    root = html.fromstring(raw)
    if text(one(root.xpath('//h1'))) != game:
        raise ValueError('Wrong schedule game')
    main = one(root.xpath('//main'))
    tables = main.xpath('.//table[@class="prize-chart__table"]')
    if len(tables) != 4:
        raise ValueError('Missing or extra schedule tables')
    size = int(game[-1])
    ways = {3: [3, 6], 4: [4, 6, 12, 24], 5: [5, 10, 20, 30, 60, 120]}[size]
    labels = [['Straight (Exact Order)'], [f'{n}-Way Box' for n in ways],
              [f'{n}-Way Straight/Box' for n in ways],
              [f'{n}-Way Combo' for n in ways] if size < 5 else
              ['Front 4', 'Back 4', 'Front 3', 'Back 3', 'Front Pair', 'Back Pair']]
    result = []
    for index, table in enumerate(tables):
        headers = table.xpath('./thead/tr/th')
        expected = ['Play Type', 'Example Wager', 'Winning Combos'] + (
            ['Payout'] if index == 2 or (index == 3 and size < 5) else ['Payout (50¢)', 'Payout ($1)'])
        if [text(e) for e in headers] != expected:
            raise ValueError('Changed schedule columns')
        spans = [int(e.get('colspan', '1')) for e in headers]
        if spans != ([1, 1, 1, 2] if index == 3 and size < 5 else [1] * len(headers)):
            raise ValueError('Changed schedule header spans')
        rows = table.xpath('./tbody/tr')
        expected_rows = len(labels[index]) * (2 if index == 2 else 1)
        if len(rows) != expected_rows:
            raise ValueError('Missing schedule rows')
        output = []
        for i, row in enumerate(rows):
            cells = row.xpath('./td')
            continuation = index == 2 and i % 2 == 1
            if len(cells) != (2 if continuation else sum(spans)):
                raise ValueError('Changed schedule cell count')
            expected_spans = [2, 2, 1, 1] if index == 2 and not continuation else [1] * len(cells)
            if [int(e.get('rowspan', '1')) for e in cells] != expected_spans or any(e.get('colspan', '1') != '1' for e in cells):
                raise ValueError('Changed schedule cell spans')
            if not continuation:
                label = text(one(cells[0].xpath('.//span[@class="prize-chart__label"]')))
                description = text(one(cells[0].xpath('.//span[@class="prize-chart__description-meta"]')))
                if label != labels[index][i // 2 if index == 2 else i] or 'Odds -' not in description:
                    raise ValueError('Changed schedule label or missing odds')
            # Separate br-delimited wager examples and combo costs without joining words.
            values = [' '.join(' '.join(e.itertext()).split()) for e in cells]
            if any(not value for value in values):
                raise ValueError('Empty schedule cell')
            for value in values[-(1 if index == 2 else 2):]:
                match = re.fullmatch(r'(\$[\d,]+(?:\.\d{2})?)(?: \((\$[\d,]+\.\d{2}) play\))?', value)
                if not match:
                    raise ValueError('Invalid schedule payout')
                money(match[1])
                if match[2]: money(match[2])
                if bool(match[2]) != (index == 3 and size < 5):
                    raise ValueError('Missing or unexpected combo play cost')
            output.append({'cells': values, 'rowSpans': expected_spans})
        result.append({'columns': expected, 'columnSpans': spans, 'rows': output})
    notes = [text(p) for p in main.xpath('.//p') if text(p).startswith('Note:') and 'Straight/Box' in text(p)]
    limits = [text(p) for p in main.xpath('.//p') if text(p).startswith('On occasion, certain popular ' + game + ' numbers')]
    if len(notes) != 1 or len(limits) != 1 or 'liability' not in limits[0] or '$1' not in notes[0]:
        raise ValueError('Missing Pick wager or liability qualification')
    return {'game': game, 'tables': result, 'qualifications': notes + limits,
            'coverage': 'Published payout schedule and examples, not actual draw winner counts or dollar totals.'}


def parse_powerball_reports(raw, *, today=None):
    """Validate every paired history row before selecting two recent reports."""
    today = today or datetime.now(CENTRAL).date()
    game = 'Powerball'
    if b'</html>' not in raw.lower():
        raise ValueError('Unsupported game or incomplete HTML')
    slug, size, maximum = 'powerball', 5, 69
    root = html.fromstring(raw)
    if text(one(root.xpath('//h1'))) != game:
        raise ValueError('Wrong game page')
    main = one(root.xpath('//main'))
    table = one(main.xpath('.//table[@class="winning-numbers__table"]'))
    if [text(e) for e in table.xpath('./thead/tr/th')] != ['Draw Date', 'Winning Numbers', 'Jackpot']:
        raise ValueError('Changed history columns')
    rows = table.xpath('./tr | ./tbody/tr')
    for row in list(rows):
        if row.get('class') == 'winning-numbers__more':
            if text(row) != 'Load More' or len(row.xpath('./td/button[@data-winning-numbers-more]')) != 1:
                raise ValueError('Changed continuation control')
            rows.remove(row)
    if len(rows) < 4 or len(rows) % 2:
        raise ValueError('Incomplete date/report pairs')
    reports = []
    seen = set()
    for i in range(0, len(rows), 2):
        head, detail = rows[i:i+2]
        if len(head.xpath('./th')) != 1 or len(head.xpath('./td')) != 2:
            raise ValueError('Changed date row')
        stamp = one(head.xpath('./th/span[@id]'))
        draw = date.fromisoformat(stamp.get('id'))
        label = datetime.strptime(text(stamp), '%A, %B %d, %Y').date()
        if draw != label or text(stamp).split(',')[0] != draw.strftime('%A') or draw > today or draw in seen:
            raise ValueError('Invalid or duplicate draw date')
        if draw.weekday() not in (0, 2, 5):
            raise ValueError('Unexpected drawing day')
        seen.add(draw)
        sequence = one(head.xpath('./td//ul[@aria-label="winning numbers"]'))
        balls = sequence.xpath('./li')
        if len(balls) != 7 or any(n.get('class') != 'jackpot-sequence__number' for n in balls[:5]):
            raise ValueError('Changed Powerball sequence')
        numbers = [text(n) for n in balls[:5]]
        if any(not re.fullmatch(r'\d{2}', n) or not 1 <= int(n) <= 69 for n in numbers) or len(set(numbers)) != 5:
            raise ValueError('Invalid Powerball white numbers')
        powerball = text(balls[5])
        if balls[5].get('class') != 'jackpot-sequence__number jackpot-sequence__number--powerball' or not re.fullmatch(r'\d{2}', powerball) or not 1 <= int(powerball) <= 26:
            raise ValueError('Invalid Powerball red number')
        multiplier = text(one(balls[6].xpath('./strong')))
        if balls[6].get('class') != 'jackpot-sequence__multiplier' or text(one(balls[6].xpath('./span'))) != 'Power Play' or multiplier not in ('2x', '3x', '4x', '5x', '10x'):
            raise ValueError('Invalid Power Play multiplier')
        jackpot = text(one(head.xpath(".//span[contains(concat(' ',normalize-space(@class),' '),' winning-numbers__jackpot__total ')]")))
        money(jackpot.removesuffix('(ticket purchased)').strip())
        toggle = one(head.xpath('.//disclosure-toggle'))
        region = one(detail.xpath('./td/div[@class="winning-numbers__detail"]'))
        if toggle.get('controls') != region.get('id') or toggle.get('key') != region.get('aria-labelledby'):
            raise ValueError('Mismatched report association')
        tiers_table = one(region.xpath('./table'))
        if text(one(tiers_table.xpath('./caption'))) != 'Winners in Louisiana':
            raise ValueError('Changed geographic unit')
        columns = ['Winning Combinations', 'Non Power Play Winners', 'Non Power Play Prize', 'Power Play Winners', 'Power Play Prize']
        if [text(e) for e in tiers_table.xpath('./thead/tr/th')] != columns:
            raise ValueError('Changed Powerball tier columns')
        tier_rows = tiers_table.xpath('./tbody/tr')
        identities = [(5, True), (5, False), (4, True), (4, False), (3, True), (3, False), (2, True), (1, True), (0, True)]
        if len(tier_rows) != len(identities):
            raise ValueError('Missing or extra Powerball tiers')
        tiers = []
        for row, (white, red) in zip(tier_rows, identities):
            cells = row.xpath('./td')
            if len(cells) != 5:
                raise ValueError('Changed Powerball tier cells')
            prefix = f'1 through {white}' if white >= 3 else ('1 and 2' if white == 2 else ('1' if white else ''))
            expected = 'Power Ball numbers: ' + prefix + (' plus Powerball' if red and white else ('Powerball' if red else ''))
            symbols = cells[0].xpath('.//li')
            expected_classes = ['jackpot-sequence__number'] * white + (['jackpot-sequence__separator'] if red and white else []) + (['jackpot-sequence__number jackpot-sequence__number--powerball'] if red else [])
            if text(one(cells[0].xpath('.//span[@class="hide-text"]'))) != expected or [n.get('class') for n in symbols] != expected_classes:
                raise ValueError('Changed Powerball match label or symbols')
            prize, pp_count, pp_prize = text(cells[2]), text(cells[3]), text(cells[4])
            jackpot_row = white == 5 and red
            if jackpot_row:
                if (prize, pp_count, pp_prize) != ('JACKPOT', 'N/A', 'N/A'):
                    raise ValueError('Changed Powerball jackpot availability')
            else:
                money(prize); money(pp_prize); count(pp_count)
            tiers.append({'match': str(white) + ('+PB' if red else ''), 'sourceMatchLabel': expected,
                          'baseWinners': count(text(cells[1])), 'basePrizeLabel': prize,
                          'powerPlayWinners': None if jackpot_row else count(pp_count),
                          'powerPlayWinnersLabel': pp_count, 'powerPlayPrizeLabel': pp_prize})
        updated = text(one(tiers_table.xpath('./tfoot/tr/td/p')))
        timestamp = source_time(updated, today)
        warnings = []
        if timestamp.date() < draw:
            warnings.append('The printed source update date precedes the draw date. Both dates are retained without correction.')
        reports.append({'game': game, 'session': 'Drawing', 'drawDate': draw.isoformat(),
                        'numbers': numbers, 'powerball': powerball, 'powerPlay': multiplier, 'advertisedJackpot': jackpot, 'tiers': tiers,
                        'sourceUpdatedText': updated, 'sourceUpdatedAt': timestamp.isoformat(),
                        'sourceWarnings': warnings,
                        'sourceUrl': f'https://louisianalottery.com/draw-games/{slug}/#{draw.isoformat()}',
                        'coverage': 'Source-reported Louisiana winners by tier, not certified distinct tickets or people, complete claims, or retailer activity. Jackpot advertisement is not a paid total.'})
    reports.sort(key=lambda r: r['drawDate'], reverse=True)
    return reports[:2]
