from pathlib import Path
import unittest
from lxml import html
from tooling.idaho_instaplay import SPECS, parse_detail

FIXTURES = Path(__file__).parent / 'fixtures'


class IdahoInstaplayTest(unittest.TestCase):
    def raw(self, slug):
        return (FIXTURES / f'idaho_instaplay_{slug}.html').read_bytes()

    def test_reviewed_catalog_details(self):
        games = [parse_detail(self.raw(s), s) for s in SPECS]
        self.assertEqual(len(games), 12)
        self.assertEqual(sum(len(g['tiers']) for g in games), 110)
        self.assertTrue(all(g['remainingPrizes'] is None for g in games))
        self.assertEqual(games[1]['tiers'][0]['schedulePrizeCount'], 2)

    def test_placeholders_are_not_zero_prizes(self):
        cash = parse_detail(self.raw('10-cash-spot'), '10-cash-spot')
        self.assertTrue(all(t['prizeDollars'] is None for t in cash['tiers']))
        jackpot = parse_detail(self.raw('idaho-jackpot'), 'idaho-jackpot')
        self.assertIsNone(jackpot['tiers'][0]['prizeDollars'])
        self.assertEqual(jackpot['tiers'][1]['prizeDollars'], 500)
        self.assertEqual(jackpot['tiers'][4]['sourceOdds'], '1:640')

    def test_mutations_require_review(self):
        for slug in SPECS:
            for mode in ['count', 'prize', 'odds', 'missing', 'rule', 'title', 'duplicate']:
                with self.subTest(slug=slug, mode=mode):
                    doc = html.fromstring(self.raw(slug)); row = doc.xpath('//tbody/tr')[0]
                    if mode in ['count', 'prize', 'odds']:
                        row.xpath('./td')[['count', 'prize', 'odds'].index(mode)].text = '0'
                    elif mode == 'missing': row.getparent().remove(row)
                    elif mode == 'rule': doc.xpath('//*[@id="tab2"]')[0].text = 'Changed rule'
                    elif mode == 'title': doc.xpath('//head/title')[0].text = 'Other Game'
                    else:
                        table = html.Element('table');doc.xpath('//body')[0].append(table)
                    with self.assertRaises(ValueError): parse_detail(html.tostring(doc), slug)

    def test_wrong_game_rejected(self):
        with self.assertRaises(ValueError): parse_detail(self.raw('bank-buster'), 'blackjack')
        with self.assertRaises(ValueError): parse_detail(self.raw('bank-buster'), 'unknown')
