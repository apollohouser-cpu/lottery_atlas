import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
from north_carolina_scratch_catalog import parse_catalog
from import_north_carolina_scratch_catalog import refresh


def fixture(n=1,date='10/7/2026',total='5',remaining='4',status='Reordered'):
    tables=[]
    for i in range(1,n+1):
        tables.append(f'''<div class="box price_10"><table class="datatable"><thead>
        <tr><th><span class="gamename"><a href="/scratch-off/{i}/sample-game">Sample {i}</a></span>
        <span class="gamenumber">Game Number: {i}</span><span class="gameflags">{status}</span></th></tr>
        <tr><th>Value</th><th>Odds 1 in</th><th>Total</th><th>Remaining</th></tr></thead>
        <tbody><tr><td>$50,000/YR FOR LIFE</td><td>1,000.25</td><td>{total}</td><td>{remaining}</td></tr></tbody></table></div>''')
    return ('<html><main>'+''.join(tables)+f'<p>Remaining prizes are updated daily and shows prizes not yet claimed through {date}. A status of "Reordered" indicates the prize count has increased.</p></main></html>').encode()


class NCCatalogTests(unittest.TestCase):
    def test_literal_prize_status_and_counts(self):
        result=parse_catalog(fixture()); game=result['games'][0]
        self.assertEqual(result['sourceDate'],'2026-10-07')
        self.assertEqual(game['ticketPrice'],10)
        self.assertEqual(game['statusLabel'],'Reordered')
        self.assertEqual(game['tiers'][0],dict(prizeLabel='$50,000/YR FOR LIFE',oddsLabel='1,000.25',totalPrizes=5,remainingPrizes=4))
        self.assertNotIn('claimedPrizes',game['tiers'][0])

    def test_invalid_structure_identity_and_values(self):
        original=fixture()
        mutations=[(b'</html>',b''),(b'10/7/2026',b'2/30/2026'),
            (b'/scratch-off/1/',b'/scratch-off/2/'),(b'/scratch-off/1/',b'https://example.com/scratch-off/1/'),
            (b'<th>Remaining</th>',b'<th>Sold</th>'),(b'<td>4</td>',b'<td>-1</td>'),
            (b'<td>4</td>',b'<td>6</td>'),(b'1,000.25',b'1,,000'),
            (b'price_10',b'price_0'),(b'not yet claimed through',b'unknown through')]
        for before,after in mutations:
            with self.subTest(before=before):
                with self.assertRaises(ValueError):parse_catalog(original.replace(before,after))
        with self.assertRaises(ValueError):parse_catalog(fixture(2).replace(b'Game Number: 2',b'Game Number: 1'))

    def test_refresh_preserves_bytes_dates_on_failures(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp)/'catalog.json';refresh(out,lambda _:fixture(50));before=out.read_bytes()
            for raw in [fixture(49,date='10/6/2026'),fixture(1),fixture(50).replace(b'Sample 1<',b'Changed 1<'),fixture(50,date='12/31/2099'),fixture(50).replace(b'$50,000/YR FOR LIFE',b'$1')]:
                with self.assertRaises(ValueError):refresh(out,lambda _:raw)
                self.assertEqual(out.read_bytes(),before)
            def fail(_):raise OSError('network fixture outage')
            with self.assertRaises(OSError):refresh(out,fail)
            self.assertEqual(out.read_bytes(),before)
            refresh(out,lambda _:fixture(50));self.assertEqual(out.read_bytes(),before)

    def test_reorder_increases_are_literal_not_claim_deltas(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp)/'catalog.json';refresh(out,lambda _:fixture(50))
            after=refresh(out,lambda _:fixture(50,total='10',remaining='9'))
            self.assertEqual(after['games'][0]['tiers'][0]['remainingPrizes'],9)
            self.assertNotIn('winningTickets',json.dumps(after))
