from pathlib import Path
from datetime import date
import unittest
from tooling.idaho_scratch_coverage import build_scratch
from test_idaho_scratch_catalog import catalog, detail, table

F = Path(__file__).parent / 'fixtures'
CARD = (F/'idaho_unavailable_scratch_card.html').read_bytes()
DETAIL = (F/'idaho_unavailable_scratch_detail.html').read_bytes()
CLAIMS = table(['Number','Game Name','Official Game End','Last Day to Claim'],[['9999','Other','September 21, 2026','March 20, 2027']])


class ScratchCoverageTest(unittest.TestCase):
    def build(self, card=CARD, raw=DETAIL):
        return build_scratch(card, CLAIMS, lambda url:raw, as_of=date(2026,10,23))

    def test_unavailable_preserved_not_zero(self):
        result = self.build()
        self.assertEqual(result['games'], [])
        game = result['unavailableInventoryGames'][0]
        self.assertEqual(len(game['prizeStructure']), 11)
        self.assertTrue(all(t['remaining'] is None for t in game['prizeStructure']))
        self.assertIsNone(game['sourceDate'])
        self.assertEqual(game['cost'], 5)

    def test_changed_or_partial_unknown_rejected(self):
        for raw in [DETAIL.replace(b'*not available',b'0',1), DETAIL.replace(b'1933_scratched',b'9999_scratched'), DETAIL.replace(b'10/22/2026',b'10/23/2026')]:
            with self.assertRaises(ValueError): self.build(raw=raw)
        with self.assertRaises(ValueError): self.build(card=CARD.replace(b'data-game-id="1933"',b'data-game-id="9999"'))
        with self.assertRaises(ValueError): self.build(card=CARD+CARD)

    def test_mixed_complete_collection(self):
        result = build_scratch(b'<html><body>'+CARD+catalog().encode()+b'</body></html>', CLAIMS,
            lambda url: DETAIL if 'mistletoe' in url else detail(), as_of=date(2026,10,23))
        self.assertEqual(result['listedGameCount'],2)
        self.assertEqual(len(result['games']),1)
        self.assertEqual(len(result['unavailableInventoryGames']),1)
        self.assertEqual(result['games'][0]['topPrizesRemaining'],0)

    def test_failure_and_unreviewed_blank_abort(self):
        with self.assertRaises(OSError):
            build_scratch(CARD,CLAIMS,lambda url: (_ for _ in ()).throw(OSError('failure')),as_of=date(2026,10,23))
        with self.assertRaises(ValueError): self.build(card=catalog().replace('>3<','><').encode())
