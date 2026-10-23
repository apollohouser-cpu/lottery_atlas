from datetime import date
from pathlib import Path
import unittest
from lxml import html
from tooling.idaho_mfl_report import parse_report

RAW = (Path(__file__).parent / 'fixtures/idaho_mfl_report.html').read_bytes()


class IdahoMflReportTests(unittest.TestCase):
    def parse(self, raw=RAW, requested='2026-10-21'):
        return parse_report(raw, requested, as_of=date(2026, 10, 22))

    def test_latest_exact_join_and_older_gap(self):
        r = self.parse()
        self.assertEqual(len(r['tiers']), 9)
        self.assertEqual(r['tiers'][-1]['publishedWinnerCount'], 198)
        self.assertIsNone(self.parse(requested='2026-10-20'))
        with self.assertRaises(ValueError): self.parse(requested='2026-10-19')

    def test_source_identity_mutations(self):
        for before, after in [(b'data-region="idaho"', b'data-region="national"'),
                              (b'value="10/21/26"', b'value="10/19/26"'),
                              (b'data-number="XXXXXY"', b'data-number="XXXXX"'),
                              (b'$7,500', b'$7,501')]:
            with self.subTest(before=before), self.assertRaises(ValueError):
                self.parse(RAW.replace(before, after))

    def test_malformed_counts_reject_even_for_older_request(self):
        for value in ['N/A', '-1', '1.0', '9007199254740992']:
            tree = html.fromstring(RAW)
            tree.xpath('//td[@class="millionaire_for_life"]')[0].text = value
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.parse(html.tostring(tree), requested='2026-10-20')

    def test_missing_or_duplicate_rows(self):
        for mode in ['missing', 'duplicate']:
            tree = html.fromstring(RAW)
            row = tree.xpath('//table[contains(@class,"idaho-table")]/tbody/tr')[0]
            if mode == 'missing': row.getparent().remove(row)
            else: row.addnext(html.fromstring(html.tostring(row)))
            with self.subTest(mode=mode), self.assertRaises(ValueError): self.parse(html.tostring(tree))


if __name__ == '__main__': unittest.main()
