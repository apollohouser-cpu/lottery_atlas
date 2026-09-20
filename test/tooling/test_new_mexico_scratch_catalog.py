import importlib.util
from datetime import date
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('nm',Path(__file__).resolve().parents[2]/'tooling/import_new_mexico_scratch_catalog.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
TODAY=date(2026,9,20)
def inventory(count='0'):
    return '<p class="top-prizes-update-time"><strong>September 20, 2026 03:17 PM</strong></p><table><thead><tr>'+''.join('<th>'+h+'</th>' for h in ['Ticket Cost','Game #','Game Name','Top Prize Amount','Top Prizes Remaining'])+'</tr></thead><tbody><tr><td>$5</td><td>600</td><td>Example</td><td>$50,000</td><td>'+count+'</td></tr></tbody></table>'
def endings(gid='600',end='9/1/2026',claim='12/1/2026'):
    return '<table><tr><th>Game #</th><th>Game</th><th>End Date</th><th>Last Day to Redeem</th></tr><tr><td>'+gid+'</td><td>Other spelling</td><td>'+end+'</td><td>'+claim+'</td></tr></table><table></table>'
class NewMexicoTest(unittest.TestCase):
    def test_estimate_date_zero_and_redeemable_status(self):
        r=m.build_catalog(inventory(),endings(),TODAY);g=r['games'][0]
        self.assertEqual(g['topPrizesRemaining'],0);self.assertEqual(r['sourceDate'],'2026-09-20')
        self.assertIsNone(r['sourceTimezone']);self.assertEqual(g['lastDayToRedeem'],'2026-12-01')
        self.assertIn('Estimated',g['inventoryNote'])
    def test_expiration_boundary(self):
        self.assertEqual(len(m.build_catalog(inventory(),endings(claim='9/20/2026'),TODAY)['games']),1)
        with self.assertRaises(ValueError):m.build_catalog(inventory(),endings(claim='9/19/2026'),TODAY)
    def test_matched_bad_dates_stop_unrelated_anomaly_retained(self):
        with self.assertRaises(ValueError):m.build_catalog(inventory(),endings(end='9/1/2204'),TODAY)
        r=m.build_catalog(inventory(),endings(gid='999',end='9/1/2204'),TODAY)
        self.assertEqual(r['unrelatedEndingDateAnomalies'],['999'])
    def test_missing_negative_counts_and_future_source(self):
        for value in ['', '-1','1,00']:
            with self.subTest(value=value),self.assertRaises(ValueError):m.parse_inventory(inventory(value))
        with self.assertRaises(ValueError):m.build_catalog(inventory(),endings(),date(2026,9,19))
    def test_changed_ending_schema_rejected(self):
        with self.assertRaises(ValueError):m.build_catalog(inventory(),endings().replace('Last Day to Redeem','Changed'),TODAY)
if __name__=='__main__':unittest.main()
