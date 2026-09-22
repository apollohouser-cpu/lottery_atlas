import importlib.util
from datetime import date
from pathlib import Path
import unittest
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('ne',Path(__file__).resolve().parents[2]/'tooling/import_nebraska_scratch_catalog.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
TODAY=date(2026,9,20)
def report(games=None):return dict(source=m.REPORT,sourceSha256='a'*64,sourceDate='2026-09-13',games=games if games is not None else [dict(id='1335',topPrize=500,topPrizesRemaining=10)])
def detail():return '<img src="/images/scratch/ticket_art/1335_art.jpg"><strong>1335 Pocket Change 5X</strong><table><tr><th>Prize</th><th>Odds</th><th>Winners**</th></tr><tr><td>$500</td><td>84,000.00</td><td>6</td></tr><tr><td>$500</td><td>56,000.00</td><td>9</td></tr><tr><td>Free $1 Ticket</td><td>8.00</td><td>63000</td></tr></table>'
class NebraskaTest(unittest.TestCase):
    def test_navigation_promotions_do_not_become_catalog_rows(self):
        card='<div class="row"><div class="scratch_ball"><div>$1</div></div><div><div class="card"><div class="card-body"><a href="/scratch-detail?gameid=1035"></a><strong>Pocket Change 5X</strong></div></div></div></div>'
        nav='<div class="sbm_contain_all"><a href="/scratch-detail?gameid=1035"><h3>Promotional duplicate</h3></a></div>'
        games=m.parse_listing('<html>'+nav+card+'</html>')
        self.assertEqual(len(games),1);self.assertEqual(games[0]['cost'],1)
        with self.assertRaises(ValueError):m.parse_listing('<html>'+card+card+'</html>')
        with self.assertRaises(ValueError):m.parse_listing(card.replace('$1','unknown'))
    def test_printed_identity_and_repeated_structure_rows(self):
        g=m.parse_detail(detail(),dict(name='Pocket Change 5X',cost=1,url='https://nelottery.com/scratch-detail?gameid=1035'))
        self.assertEqual(g['id'],'1335');self.assertEqual(g['topPrize'],500)
        self.assertEqual(len(g['prizeStructure']),3);self.assertNotIn('topPrizesRemaining',g)
        self.assertNotIn('prizeAmount',g['prizeStructure'][-1])
    def test_dated_join_and_missing_is_unknown(self):
        c=m.join_report([dict(id='1335',topPrize=500),dict(id='1344',topPrize=50000)],report(),TODAY)
        self.assertEqual(c['games'][0]['topPrizesRemaining'],10)
        self.assertNotIn('topPrizesRemaining',c['games'][1]);self.assertEqual(c['sourceDate'],'2026-09-13')
    def test_mismatched_top_prize_rejected(self):
        with self.assertRaises(ValueError):m.join_report([dict(id='1335',topPrize=1000)],report(),TODAY)
    def test_duplicate_and_negative_report_rows_rejected(self):
        g=report()['games'][0]
        for rows in [[g,g],[dict(g,topPrizesRemaining=-1)],[dict(g,topPrizesRemaining=True)]]:
            with self.subTest(rows=rows),self.assertRaises(ValueError):m.reviewed_counts(report(rows),TODAY)
    def test_future_report_and_changed_detail_schema_rejected(self):
        r=report();r['sourceDate']='2026-09-21'
        with self.assertRaises(ValueError):m.reviewed_counts(r,TODAY)
        with self.assertRaises(ValueError):m.parse_detail(detail().replace('Winners**','Claims'),dict(name='Pocket Change 5X',cost=1,url='example'))
    def test_new_badge_is_not_part_of_game_name(self):
        from lxml import html
        self.assertEqual(m.listing_name(html.fromstring('<strong>New! Fortune<br/><span style="color:RED;">New!</span></strong>')), 'New! Fortune')
        self.assertEqual(m.listing_name(html.fromstring('<strong>Fortune <span>Plus</span></strong>')), 'Fortune Plus')
        with self.assertRaisesRegex(ValueError,'name mismatch'):
            m.parse_detail(detail(),dict(name='Another Game',cost=1,url='example'))

    def test_bare_cash_labels_preserve_structure_without_inventory(self):
        g=m.parse_detail(detail().replace('<td>$500</td>','<td>500</td>'),dict(name='Pocket Change 5X',cost=1,url='example'))
        self.assertEqual(g['topPrize'],500)
        self.assertEqual(g['prizeStructure'][0]['prizeLabel'],'500')
        self.assertNotIn('topPrizesRemaining',g)
        for label in ['500 points','5,00','0']:
            with self.subTest(label=label),self.assertRaises(ValueError):
                m.parse_detail(detail().replace('<td>$500</td>',f'<td>{label}</td>'),dict(name='Pocket Change 5X',cost=1,url='example'))

    def test_conflicting_identity_is_excluded_then_restored(self):
        listing=[dict(name='Pocket Change 5X',cost=1,url='example')]
        with patch.object(m,'fetch',return_value=detail().replace('1335_art','1336_art')):
            games,excluded=m.import_details(listing)
        self.assertEqual(games,[]);self.assertEqual(len(excluded),1)
        self.assertIn('1336',excluded[0]['reason'])
        catalog=m.join_report(games,report(),TODAY,excluded)
        self.assertIn('Excluded unverified identities',catalog['coverage'])
        with patch.object(m,'fetch',return_value=detail()):
            games,excluded=m.import_details(listing)
        self.assertEqual(len(games),1);self.assertEqual(excluded,[])
        self.assertNotIn('excludedGames',m.join_report(games,report(),TODAY,excluded))
        for raw in [detail().replace('Winners**','Claims'),detail().replace('1335_art','unknown_art'),detail().replace('<img src="/images/scratch/ticket_art/1335_art.jpg">','')]:
            with patch.object(m,'fetch',return_value=raw),self.assertRaises(ValueError):m.import_details(listing)

if __name__=='__main__':unittest.main()
