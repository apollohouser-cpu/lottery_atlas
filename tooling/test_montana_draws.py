import unittest
from pathlib import Path
from tooling.import_montana_draws import parse_draws,SPECS

class MontanaDrawsTest(unittest.TestCase):
    def source(self,game='powerball'):
        slug='powerball' if game=='powerball-double-play' else game
        return Path('tooling/fixtures/montana/'+slug+'.html').read_text()
    def parse(self,text,game='powerball',at='2026-10-28T04:27:20+00:00'):
        return parse_draws(text,game,retrieved_at=at)
    def reject(self,text,game='powerball',**kw):
        with self.assertRaises(ValueError):self.parse(text,game,**kw)
    def test_all_retained_tables(self):
        rows=[r for g in SPECS for r in self.parse(self.source(g),g)]
        self.assertEqual(len(rows),709)
        self.assertTrue(all(r['reportStatus']=='unavailable' and r['datePrecision']=='day' for r in rows))
    def test_variants_separate(self):
        a=self.parse(self.source())[0];b=self.parse(self.source(),'powerball-double-play')[0]
        self.assertEqual(a['numbers'],[18,26,49,50,54]);self.assertEqual(b['numbers'],[5,11,14,24,59]);self.assertIsNone(b['multiplier'])
    def test_ignores_headline_and_winner_tables(self):
        a=self.source();b='<h2>Draw Date: October 27, 2026</h2><table><tr><td>999 winners</td></tr></table>'+a
        self.assertEqual(self.parse(a),self.parse(b))
    def test_wrong_identity_or_header(self):
        self.reject(self.source().replace('Powerball - Montana Lottery','Other - Montana Lottery'))
        self.reject(self.source().replace('>PP<','>XX<'))
    def test_missing_extra_table(self):
        self.reject(self.source()+self.source())
        self.reject(self.source().replace('winning-numbers-table','other',1))
    def test_number_validation(self):
        for v in ['18, 18, 49, 50, 54','0, 26, 49, 50, 54','70, 26, 49, 50, 54','18, 26','18,26,49,50,54']:
            self.reject(self.source().replace('18, 26, 49, 50, 54',v,1))
    def test_date_cadence_order_floor(self):
        for v in ['10.25.2026','10.24.2026','04.25.2026','02.30.2026']:
            self.reject(self.source().replace('10.26.2026',v,1))
    def test_capture_bounds(self):
        self.reject(self.source(),at='2026-10-26T00:00:00Z')
        self.reject(self.source(),at='2026-10-28T04:00:00')
        self.reject(self.source(),at='2026-10-28T04:00:00+01:00')
    def test_multiplier_and_jackpot(self):
        self.reject(self.source().replace('<td>3</td>','<td>9</td>',1))
        self.reject(self.source().replace('$687,000,000','not a payout',1))
    def test_cash_reconciliation(self):
        self.reject(self.source('montana-cash').replace('$231,656','$231,657',1),'montana-cash')
    def test_merged_unclosed_cells(self):
        self.reject(self.source().replace('<td>','<td colspan="2">',1))
        self.reject(self.source().replace('</td>','',1))
    def test_no_retired_or_unknown(self):
        self.reject(self.source(),'lucky-for-life')
        self.assertIsNone(self.parse(self.source('mega-millions'),'mega-millions')[0]['multiplier'])

if __name__=='__main__':unittest.main()
