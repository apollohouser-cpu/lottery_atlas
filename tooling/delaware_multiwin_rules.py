"""Grouped literal Multi-Win schedules; page aggregates are not imported."""
import re
from lxml import html
from tooling.delaware_multiwin_report import text

SOURCE = 'https://www.delottery.com/Drawing-Games/Multi-Win-Lotto/Prizes-And-Odds'
ZERO_NOTE = 'Note: Zero numbers means that there were absolutely no numbers matched on any three lines'
ODDS_URL = 'https://delotterywebcontent.blob.core.windows.net/delottery-site-assets/assets/games/multiwin/MultiWinLottoOdds.pdf'


def parse(raw, *, source_url):
    if source_url != SOURCE:
        raise ValueError('Wrong source')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != ['Prizes And Odds - Multi Win Lotto - Drawing Games | Delaware Lottery']:
        raise ValueError('Wrong rule identity')
    tables = tree.xpath('//table')
    if len(tables) != 2:
        raise ValueError('Changed schedule tables')
    groups = []
    for table, label, matches in zip(tables, ['Win in a line', 'Combination win'], [[6,5,4,3], [10,9,8,7,6,0]]):
        if [text(n) for n in table.getparent().xpath('./h3')] != [label]:
            raise ValueError('Changed schedule group')
        if [text(n) for n in table.xpath('./thead/tr/th')] != ['Match', 'Win']:
            raise ValueError('Changed columns')
        rows = table.xpath('./tbody/tr')
        if len(rows) != len(matches) + (label == 'Combination win'):
            raise ValueError('Changed tier count')
        tiers = []
        for row, match in zip(rows, matches):
            cells = row.xpath('./td')
            if [n.get('data-label') for n in cells] != ['Match', 'Win'] or any(n.get('colspan') or n.get('rowspan') for n in cells):
                raise ValueError('Changed tier structure')
            name, prize = [text(n) for n in cells]
            if name != f'{match} numbers' or not re.fullmatch(r'\$[1-9][0-9]*(?:,[0-9]{3})*(?: \+)?', prize):
                raise ValueError('Invalid literal match/prize')
            if ('+' in prize) != (label == 'Win in a line' and match == 6):
                raise ValueError('Changed growing prize qualification')
            tiers.append({'match': name, 'prize': prize})
        if label == 'Combination win':
            note = rows[-1].xpath('./td')
            if len(note) != 1 or note[0].get('colspan') != '2' or text(note[0]) != ZERO_NOTE:
                raise ValueError('Missing/changed zero-match qualification')
        groups.append({'label': label, 'tiers': tiers})
    links = tree.xpath('//a[@href=$url]', url=ODDS_URL)
    if len(links) != 1 or text(links[0]) != 'Overall odds of winning' or ' '.join((links[0].tail or '').split()) != 'are 1:5.7!':
        raise ValueError('Missing/changed overall odds')
    return {'sourceUrl': SOURCE, 'game': 'Multi-Win Lotto', 'groups': groups,
            'zeroMatchQualification': ZERO_NOTE, 'overallOddsText': 'Overall odds of winning are 1:5.7!',
            'oddsSourceUrl': ODDS_URL,
            'coverage': 'Literal prize schedules, not actual payouts. Undated page Total Prizes and Total Money aggregates excluded; linked odds PDF not yet audited.'}
