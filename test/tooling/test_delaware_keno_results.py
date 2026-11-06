from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_keno_results import parse, SOURCE

RAW = (Path(__file__).parents[1] / 'fixtures/delaware/keno_two_rows.html').read_text()


class KenoTest(unittest.TestCase):
    def parse(self, raw=RAW, **kwargs):
        return parse(raw, source_url=kwargs.get('source_url', SOURCE),
                     requested_date=kwargs.get('requested_date', date(2026, 11, 5)),
                     observed_date=date(2026, 11, 6))

    def test_literal_identity_time_and_bonus(self):
        rows = self.parse()['results']
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]['gameNumber'], 1464188)
        self.assertEqual(rows[0]['displayTime'], '12:02 AM')
        self.assertIsNone(rows[0]['sourceTimezone'])
        self.assertEqual(rows[1]['bonusMultiplier'], 3)
        self.assertNotIn('drawnAt', rows[0])

    def test_request_identity_and_date(self):
        for kwargs in [{'source_url': SOURCE+'/other'},
                       {'requested_date': date(2026, 11, 4)},
                       {'requested_date': date(2026, 11, 7)}]:
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError):
                self.parse(**kwargs)

    def test_number_identity_time_and_bonus_corruption(self):
        for old, new in [('>80<', '>81<'), ('>80<', '>7<'),
                         ('>1464189<', '>1464188<'), ('>12:05 AM<', '>12:01 AM<'),
                         ('>12:05 AM<', '>25:05 AM<'), ('<strong>3</strong>', '<strong>2</strong>'),
                         ('keno-results_number">80', 'other">80')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                self.parse(RAW.replace(old, new, 1))


if __name__ == '__main__':
    unittest.main()
