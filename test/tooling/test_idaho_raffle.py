from datetime import date
from pathlib import Path
import unittest
from tooling.idaho_raffle import parse_raffle

RAW = (Path(__file__).parent / 'fixtures/idaho_raffle_2026.html').read_bytes()


class IdahoRaffleTest(unittest.TestCase):
    def parse(self, raw=RAW, day=date(2026,10,23)):
        return parse_raffle(raw, as_of=day)

    def test_promotion_not_final(self):
        result = self.parse()
        self.assertIsNone(result['finalResult'])
        self.assertEqual(result['dailyPromotions'], [{'date':'2026-10-21','ticketNumber':'012426'}])
        self.assertEqual(len(result['schedule']), 8)
        self.assertEqual(result['schedule'][1][-1], '1:225000')

    def test_new_promotion_both_copies(self):
        raw = RAW.replace(b'<p>Oct 21 <strong>012426</strong></p>', b'<p>Oct 21 <strong>012426</strong></p><p>Oct 22 <strong>000001</strong></p>')
        result = self.parse(raw)
        self.assertEqual(len(result['dailyPromotions']), 2)
        self.assertEqual(result['dailyPromotions'][1]['ticketNumber'], '000001')

    def test_malformed_duplicate_and_mismatch(self):
        for replacement in [b'000000', b'500001', b'12426', b'abcdef']:
            with self.subTest(replacement=replacement), self.assertRaises(ValueError):
                self.parse(RAW.replace(b'012426', replacement))
        with self.assertRaises(ValueError): self.parse(RAW.replace(b'012426', b'012427', 1))
        with self.assertRaises(ValueError): self.parse(RAW.replace(b'<p>Oct 21 <strong>012426</strong></p>', b'<p>Oct 21 <strong>012426</strong></p>' * 2))

    def test_dates_and_contract_changes(self):
        for text in [b'Oct 24', b'Nov 10', b'Oct 20']:
            with self.assertRaises(ValueError): self.parse(RAW.replace(b'Oct 21', text))
        with self.assertRaises(ValueError): self.parse(day=date(2026,12,29))
        with self.assertRaises(ValueError): self.parse(RAW.replace(b'1:225000', b'1:250000'))
        with self.assertRaises(ValueError): self.parse(RAW.replace(b'whichever is later', b'whichever is earlier'))
