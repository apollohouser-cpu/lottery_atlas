import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tooling'))
from missouri_scratch_catalog import integer, parse_listing, validate_detail

FIELDS = {'Start Date:':'Sep 28, 2026','End Date:':'TBD','Ticket Price:':'$5','Top Prize:':'$100,000','Total Won:':'$0','Total Unclaimed:':'$200,000'}
def card():
    fields=''.join(f'<div class="scratchers-list__feature"><div class="scratchers-list__subtitle">{k}</div><div class="scratchers-list__value">{v}</div></div>' for k,v in FIELDS.items())
    return '<div class="scratchers-list__item"><div class="scratchers-list__num">#569</div><div class="scratchers-list__title">Test</div>'+fields+'<table><tbody><tr><td>$100,000</td><td>2</td><td>0</td></tr></tbody></table></div>'
def listing():return '<html><body>'+card()+'<div class="scratchers-list_big-list">'+card()+'</div></body></html>'
def detail():
    fields=''.join(f'<div class="scratchers-single-info__block"><div class="scratchers-single-info__title">{k}</div><div class="scratchers-single-info__body">{v}</div></div>' for k,v in {'Official Start Date:':'Sep 28, 2026','End Date:':'TBD','Ticket Price:':'$5'}.items())
    return '<html><body><div><div class="scratchers-single__id">Game #569</div><h1>Test</h1></div>'+fields+'<table class="table_highlight-first"><thead><tr><th>Prize Level</th><th>Total Prizes</th><th>Unclaimed Prizes</th></tr></thead><tbody><tr><td>$100,000</td><td>2</td><td>0</td></tr></tbody></table><p>The information on this page is updated daily.</p></body></html>'
class InventoryTests(unittest.TestCase):
    def test_featured_duplicate_ignored_and_literal_units_retained(self):
        games=parse_listing(listing());self.assertEqual(len(games),1)
        d=validate_detail(detail(),games[0]);self.assertIsNone(d['sourceDate']);self.assertIsNone(d['endDate']);self.assertEqual(d['advertisedTopPrize'],'$100,000');self.assertEqual(d['prizeTiers'][0]['unclaimedPrizes'],0);self.assertNotIn('claimed',d)
    def test_reject_invalid_counts_identity_dates_and_partial_inventory(self):
        game=parse_listing(listing())[0]
        for raw in [detail().replace('Game #569','Game #570'), detail().replace('Sep 28','Sep 27'),detail().replace('<td>0</td>','<td>3</td>'),detail().replace('<td>0</td>','<td></td>'),detail().replace('Unclaimed Prizes','Prizes Claimed'),detail().replace('updated daily.','updated.')]:
            with self.assertRaises(ValueError):validate_detail(raw,game)
        for v in ['1,00','-1','1.5','01','']:
            with self.assertRaises(ValueError):integer(v)
        with self.assertRaises(ValueError):parse_listing(listing().replace('</div></body>',card()+'</div></body>'))
if __name__=='__main__':unittest.main()
