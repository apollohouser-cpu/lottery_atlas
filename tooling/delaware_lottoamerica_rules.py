"""Image-audited tiers coupled to the official page's prize qualification."""
import hashlib
import json
from pathlib import Path
from lxml import html
from tooling.delaware_multiwin_report import text

SOURCE = 'https://www.delottery.com/Drawing-Games/Lotto-America/Prizes-And-Odds'
QUALIFICATION = 'The Delaware Lottery and the Multiple-State Lottery Association may limit the amount of a top prize for certain games when specific conditions are met. In such an event, all money available for that prize level may be divided equally by the number of winning tickets for that prize level (pari-mutuel prize payment). See game pari-mutuel prize descriptions or contact the Lottery Office for details.'
INTRO = 'Play LOTTO AMERICA℠ and you could win an estimated annuity jackpot start at $2 million or a set cash prize. Add All-Star Bonus Multiplier®, for an additional $1, and if you win a set cash prize, you could multiply that amount.'


def parse(raw, chart_bytes, *, source_url, chart_url):
    rules = json.loads(Path(__file__).with_name('delaware_lottoamerica_chart.json').read_text())
    if source_url != SOURCE or chart_url != rules['chartUrl'] or hashlib.sha256(chart_bytes).hexdigest() != rules['chartSha256']:
        raise ValueError('Changed rule source/image; re-audit required')
    tree = html.fromstring(raw)
    if tree.xpath('//title/text()') != ['Prizes And Odds - Lotto America - Drawing Games | Delaware Lottery']:
        raise ValueError('Wrong rule identity')
    bodies = tree.xpath('//div[@class="tab-body-area"]')
    if len(bodies) != 1:
        raise ValueError('Changed rule container')
    body = bodies[0]
    if [text(n) for n in body.xpath('./p')] != [INTRO, 'Here’s what you can win when you play:', QUALIFICATION]:
        raise ValueError('Changed jackpot/pari-mutuel qualifications')
    if body.xpath('./img/@src') != [chart_url]:
        raise ValueError('Chart/page identity mismatch')
    rules.update(sourceUrl=SOURCE, introduction=INTRO, qualification=QUALIFICATION,
                 coverage='Published prize schedule; annuity starting amount is not a current jackpot. No actual payouts or winner counts inferred.')
    return rules
