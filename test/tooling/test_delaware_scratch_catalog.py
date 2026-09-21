import importlib.util
from datetime import date, datetime
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('de', Path(__file__).resolve().parents[2] / 'tooling/import_delaware_scratch_catalog.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
TODAY = date(2026, 9, 21)
STAMP = datetime(2026, 9, 21, 14, 24, 42)
IMAGE = 'https://delotterywebcontent.blob.core.windows.net/delottery-site-assets/images/instant-lottery/instant-details/game.jpg'

def card(name='Example', price='5'):
    return f'<div class="item" data-gamenumber="528"><div data-toggle="modal" data-gamenumber="528" data-gamename="{name}" data-amount="{price}" data-topprize="30000" data-imagedetailinfo="{IMAGE}"></div></div>'

def table(headers, rows):
    return '<table><thead><tr>' + ''.join(f'<th>{h}</th>' for h in headers) + '</tr></thead><tbody>' + ''.join('<tr>' + ''.join(f'<td>{c}</td>' for c in r) + '</tr>' for r in rows) + '</tbody></table>'

def report(remaining='0'):
    return '<p>as of 9/21/2026 2:24:42 PM; routine weekly updates</p>' + table(['Game Number','Game Name','Dollar Amount','Top Prize','Total Top Prizes','Prizes Remaining'], [['528*','Example','$5','$30,000','3',remaining]])

class DelawareTest(unittest.TestCase):
    def test_zero_and_unknown_timezone(self):
        stamp, rows = m.parse_report(report())
        result = m.join(m.parse_catalog(card()), stamp, rows, {}, TODAY)
        self.assertEqual(result['games'][0]['topPrizesRemaining'], 0)
        self.assertIsNone(result['sourceTimezone'])
        self.assertEqual(result['sourceTimestampLocal'], '2026-09-21T14:24:42')

    def test_shared_designs_count_once_and_navigation_excluded(self):
        catalog = m.parse_catalog('<div data-toggle="modal" data-gamenumber="999"></div>' + card('Design A') + card('Design B'))
        stamp, rows = m.parse_report(report('3'))
        rows['410'] = dict(rows['528'])
        result = m.join(catalog, stamp, rows, {}, TODAY)
        self.assertEqual(len(result['games']), 1)
        self.assertEqual(result['games'][0]['topPrizesRemaining'], 3)
        self.assertEqual(result['games'][0]['ticketDesigns'], ['Design A','Design B'])
        self.assertEqual(result['excludedReportOnlyIds'], ['410'])

    def test_malformed_and_duplicate_cards_rejected(self):
        for raw in [card()+card(), card()+card('Other','10'), card().replace(IMAGE,'https://example.com/image'), card(price='-1')]:
            with self.subTest(raw=raw), self.assertRaises(ValueError):m.parse_catalog(raw)

    def test_bad_report_rejected(self):
        for raw in [report('4'), report('-1'), report().replace('Prizes Remaining','Claims'), report().replace('routine weekly updates',''), report().replace('9/21/2026','9/99/2026'), report().replace('</tbody>', '<tr><td>528</td><td>Example</td><td>5</td><td>30000</td><td>3</td><td>0</td></tr></tbody>')]:
            with self.subTest(raw=raw), self.assertRaises(ValueError):m.parse_report(raw)

    def test_missing_and_conflicting_joins_rejected(self):
        catalog = m.parse_catalog(card())
        _, rows = m.parse_report(report())
        for records in [{}, {'528':{**rows['528'],'cost':10}}, {'528':{**rows['528'],'topPrize':1}}, {'528':{**rows['528'],'name':'Other'}}]:
            with self.subTest(records=records), self.assertRaises(ValueError):m.join(catalog,STAMP,records,{},TODAY)
        with self.assertRaises(ValueError):m.join(catalog, STAMP, rows, {}, date(2026,9,20))

    def test_end_date_inclusive_future_and_expired_excluded(self):
        raw = table(['Name','Game Number','Date Launched','Announced End of Sales'], [['Example','528','1/1/2026','9/21/2026']])
        closeouts = m.parse_closeouts(raw)
        catalog = m.parse_catalog(card())
        _, rows = m.parse_report(report())
        self.assertEqual(len(m.join(catalog,STAMP,rows,closeouts,TODAY)['games']),1)
        with self.assertRaises(ValueError):m.join(catalog,STAMP,rows,closeouts,date(2026,9,22))
        with self.assertRaises(ValueError):m.join(catalog,STAMP,rows,{'528':dict(start=date(2027,1,1),end=date(2027,2,1))},TODAY)
        with self.assertRaises(ValueError):m.parse_closeouts(raw.replace('1/1/2026','1/1/2027'))

if __name__ == '__main__':unittest.main()
