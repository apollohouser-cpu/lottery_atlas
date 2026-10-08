"""Literal NC inventory: no derived claims, cash options, or retailer stock."""
from datetime import datetime
import re
from urllib.parse import urljoin, urlparse
from lxml import html

SOURCE = 'https://nclottery.com/scratch-off-prizes-remaining'


def text(node):
    return ' '.join(node.text_content().split())


def one(node, path):
    values = node.xpath(path)
    if len(values) != 1:
        raise ValueError('Missing or duplicate catalog field: ' + path)
    return values[0]


def count(value):
    if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)', value):
        raise ValueError('Invalid prize count')
    return int(value.replace(',', ''))


def parse_catalog(raw):
    if b'</html>' not in raw.lower():
        raise ValueError('Incomplete catalog document')
    root = html.fromstring(raw)
    note = text(one(root, '//p[contains(., "not yet claimed through")]'))
    date = re.search(r'not yet claimed through (\d{1,2}/\d{1,2}/\d{4})', note)
    if not date or 'Reordered' not in note or 'prize count has increased' not in note:
        raise ValueError('Missing inventory definitions/date')
    source_date = datetime.strptime(date[1], '%m/%d/%Y').date().isoformat()
    games = []
    seen = set()
    for table in root.xpath('//main//table[contains(concat(" ",normalize-space(@class)," ")," datatable ")]'):
        link = one(table, './/span[@class="gamename"]/a')
        number = re.fullmatch(r'Game Number: (\d+)', text(one(table, './/span[@class="gamenumber"]')))
        if not number or number[1] in seen or not text(link):
            raise ValueError('Invalid/duplicate game identity')
        game_id = number[1]; seen.add(game_id)
        url = urljoin(SOURCE, link.get('href', ''))
        parsed = urlparse(url)
        if parsed.scheme != 'https' or parsed.netloc != 'nclottery.com' or not re.fullmatch(r'/scratch-off/'+game_id+r'/[a-z0-9-]+', parsed.path) or parsed.query or parsed.fragment:
            raise ValueError('Game identity/detail URL mismatch')
        parent = one(table, 'ancestor::div[contains(@class,"price_")][1]')
        price = re.findall(r'(?:^|\s)price_(\d+)(?:\s|$)', parent.get('class',''))
        if len(price) != 1 or int(price[0]) <= 0:
            raise ValueError('Missing ticket price')
        headers = [text(x) for x in table.xpath('./thead/tr[last()]/th')]
        if headers != ['Value','Odds 1 in','Total','Remaining']:
            raise ValueError('Changed prize columns')
        tiers = []; prizes = set()
        for row in table.xpath('./tbody/tr'):
            cells = row.xpath('./td')
            if len(cells) != 4: raise ValueError('Incomplete tier row')
            prize, odds, total, remaining = map(text, cells)
            if not prize or prize in prizes: raise ValueError('Missing/duplicate prize tier')
            prizes.add(prize)
            if not re.fullmatch(r'(?:[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d+)?',odds) or float(odds.replace(',','')) <= 0:
                raise ValueError('Invalid printed odds')
            total,remaining = count(total),count(remaining)
            if remaining > total: raise ValueError('Remaining exceeds source total')
            tiers.append(dict(prizeLabel=prize,oddsLabel=odds,totalPrizes=total,remainingPrizes=remaining))
        if not tiers: raise ValueError('Missing prize tiers')
        games.append(dict(id=game_id,name=text(link),ticketPrice=int(price[0]),sourceUrl=url,
                          statusLabel=text(one(table,'.//span[@class="gameflags"]')) or None,
                          notes=' '.join(text(x) for x in table.xpath('./tfoot') if text(x)),tiers=tiers))
    if not games: raise ValueError('Missing games')
    return dict(stateCode='NC',sourceUrl=SOURCE,sourceDate=source_date,sourceDefinition=note,
                coverage='Listed NC Scratch-Off prize inventory, not yet claimed as of the source date. Reorders can increase counts. No derived claims, cash-option conversion, retailer stock or statewide ticket/person total.',
                games=sorted(games,key=lambda g:int(g['id'])))
