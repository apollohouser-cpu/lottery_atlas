import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('ia',Path(__file__).resolve().parents[2]/'tooling/import_iowa_scratch_catalog.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

def report(rows=None):
    if rows is None:rows=[['Example (123)','Scratch','5','$50000','1','2'],['Example (123)','Scratch','5','$50','30','70']]
    header=''.join(f'<th>{h}</th>' for h in ['Game Name (Game Number)','Game Type','Cost','Prize','Claimed','Unclaimed'])
    body=''.join('<tr>'+''.join(f'<td>{v}</td>' for v in r)+'</tr>' for r in rows)
    return f'<label id="ContentPlaceHolder1_DataAsOf">9/18/2026</label><table id="RemainPrizes_JS_DATATABLE"><thead><tr>{header}</tr></thead><tbody>{body}</tbody></table>'

def detail():
    rows=[('Game Start:','01/01/2026'),('End Distribution:','08/01/2026'),('Official Game End:','09/01/2026'),('Last Day To Redeem Prizes:','12/01/2026')]
    return '<p id="ContentPlaceHolder1_gameDetail_Title">Win Up To $50,000!</p><table id="Dates">'+''.join(f'<tr><td>{k}</td><td>{v}</td></tr>' for k,v in rows)+'</table>'

class IowaTest(unittest.TestCase):
    def test_highest_tier_supplies_count_not_sum_of_all_tiers(self):
        day,games=m.parse_report(report());self.assertEqual(day,'2026-09-18');self.assertEqual(games[0]['topPrizesRemaining'],2);self.assertEqual(len(games[0]['prizeTiers']),2)
    def test_other_game_types_do_not_become_scratch(self):
        rows=[['Example (123)','Scratch','5','$50000','1','2'],['Pull (123)','PullTab','.50','$100','1','2']]
        self.assertEqual(len(m.parse_report(report(rows))[1]),1)
    def test_missing_negative_and_duplicate_counts_rejected(self):
        for value in ['', '-1','1.5']:
            with self.assertRaises(ValueError):m.parse_report(report([['Example (123)','Scratch','5','$50000','1',value]]))
        row=['Example (123)','Scratch','5','$50000','1','2']
        with self.assertRaises(ValueError):m.parse_report(report([row,row]))
    def test_game_dates_remain_distinct(self):
        day,games=m.parse_report(report());g=m.verify_detail(detail(),games[0],day)
        self.assertEqual(g['endDistributionDate'],'2026-08-01');self.assertEqual(g['gameEndDate'],'2026-09-01');self.assertEqual(g['lastDayToRedeem'],'2026-12-01');self.assertIn('$50 or more only',g['inventoryNote'])
    def test_wrong_top_prize_and_missing_dates_rejected(self):
        day,games=m.parse_report(report())
        with self.assertRaises(ValueError):m.verify_detail(detail().replace('$50,000','$5,000'),games[0],day)
        with self.assertRaises(ValueError):m.verify_detail(detail().replace('Game Start:','Unknown:'),games[0],day)
    def test_source_date_and_table_schema_required(self):
        for raw in [report().replace('9/18/2026','not dated'),report().replace('<th>Unclaimed</th>','<th>Other</th>')]:
            with self.assertRaises(ValueError):m.parse_report(raw)

if __name__=='__main__':unittest.main()
