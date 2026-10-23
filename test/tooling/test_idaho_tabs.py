from pathlib import Path
import unittest
from lxml import html
from tooling.idaho_tabs import SPECS, parse_detail

FIXTURES = Path(__file__).parent / 'fixtures'


class IdahoTabsTest(unittest.TestCase):
    def raw(self, slug):
        return (FIXTURES / f'idaho_tab_{slug}.html').read_bytes()

    def test_all_types_and_rows(self):
        games = [parse_detail(self.raw(s), s) for s in SPECS]
        self.assertEqual(len(games), 11)
        self.assertEqual(sum(g['scheduleType'] == 'touch_wager' for g in games), 9)
        self.assertEqual(sum(len(g['tiers']) for g in games), 46)
        self.assertTrue(all(g['remainingPrizes'] is None for g in games))
        fixed = parse_detail(self.raw('huntin-riches'), 'huntin-riches')
        self.assertEqual(fixed['tiers'][0]['schedulePrizeCount'], 1)
        self.assertEqual(fixed['tiers'][0]['prizeCents'], 25000)
        self.assertNotIn('wagerCents', fixed['tiers'][0])

    def test_fractional_money_and_qualifications(self):
        game = parse_detail(self.raw('treasure-valley-saloon-touchtab'), 'treasure-valley-saloon-touchtab')
        self.assertEqual(game['tiers'][0]['wagerCents'], 25)
        self.assertEqual(game['tiers'][0]['topPrizeCents'], 5075)
        self.assertEqual(game['tiers'][1]['topPrizeCents'], 10175)
        self.assertIn('day of play', game['rules'])
        self.assertIn('determined by amount wagered', game['sourceOddsText'])
        self.assertNotIn('schedulePrizeCount', game['tiers'][0])

    def test_mutations_fail_closed(self):
        for slug in SPECS:
            for mode in ['value', 'missing', 'header', 'rule', 'duplicate']:
                with self.subTest(slug=slug, mode=mode):
                    doc = html.fromstring(self.raw(slug));row = doc.xpath('//tbody/tr')[0]
                    if mode == 'value': row.xpath('./td')[0].text = '$0.00'
                    elif mode == 'missing': row.getparent().remove(row)
                    elif mode == 'header': doc.xpath('//th')[0].text = 'Remaining prizes'
                    elif mode == 'rule': doc.xpath('//*[@id="tab2"]')[0].text = 'Changed'
                    else: doc.xpath('//body')[0].append(html.Element('table'))
                    with self.assertRaises(ValueError): parse_detail(html.tostring(doc), slug)

    def test_wrong_variant_rejected(self):
        with self.assertRaises(ValueError): parse_detail(self.raw('huntin-riches'), 'huntin-riches-touchtab')
        with self.assertRaises(ValueError): parse_detail(self.raw('huntin-riches'), 'unknown')
