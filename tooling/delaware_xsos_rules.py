"""Source-literal prize schedule with mandatory pari-mutuel qualifications."""
import re
from lxml import html
from tooling.delaware_multiwin_report import text

SOURCE = 'https://www.delottery.com/Drawing-Games/Powerball-Xs-And-Os/Prizes-And-Odds'
QUALIFICATION = '*The jackpot prize is a cash prize and will be determined on a pari-mutuel basis. Lower-tier prizes may become pari-mutuel in some circumstances. Powerball Xs & Os™ results are randomly drawn and not based on, determined by, or dependent on the outcome of NFL games.'


def parse(raw, *, source_url):
    if source_url != SOURCE:
        raise ValueError('Wrong rule source')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != ['Prizes And Odds - Powerball Xs And Os - Drawing Games | Delaware Lottery']:
        raise ValueError('Wrong rule identity')
    tables = tree.xpath('//table')
    if len(tables) != 1:
        raise ValueError('Changed tables')
    table = tables[0]
    if [text(n) for n in table.xpath('./thead/tr/th')] != ['Match', 'Prize*', 'Odds']:
        raise ValueError('Changed columns')
    tiers = []
    for row in table.xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if [n.get('data-label') for n in cells] != ['Match', 'Prize', 'Odds']:
            raise ValueError('Changed tier structure')
        match, prize, odds = [text(n) for n in cells]
        if not re.fullmatch(r'1:[1-9][0-9]*(?:,[0-9]{3})*', odds):
            raise ValueError('Invalid literal odds')
        if prize != 'Jackpot' and not re.fullmatch(r'\$[1-9][0-9]*(?:,[0-9]{3})*', prize):
            raise ValueError('Invalid literal prize')
        tiers.append({'match': match, 'prize': prize, 'odds': odds})
    if [r['match'] for r in tiers] != ['Match 8', 'Match 7', 'Match 6', 'Match 5', 'Match 4'] or tiers[0]['prize'] != 'Jackpot':
        raise ValueError('Changed tier identities')
    parent = table.getparent()
    qualifications = parent.xpath('./p[@class="xsmall"]')
    overall = parent.xpath('./p/strong')
    if len(qualifications) != 1 or text(qualifications[0]) != QUALIFICATION:
        raise ValueError('Missing/changed prize qualification')
    if len(overall) != 1 or not re.fullmatch(r'Overall odds of winning are approximately 1:[0-9]+\.[0-9]+\.', text(overall[0])):
        raise ValueError('Missing/changed overall odds')
    return {'sourceUrl': SOURCE, 'game': 'Powerball Xs & Os', 'tiers': tiers,
            'overallOddsText': text(overall[0]), 'qualification': QUALIFICATION,
            'coverage': 'Published prize schedule, not actual payouts or winning-ticket counts. Second-chance entries are outside this rule dataset.'}
