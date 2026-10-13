from datetime import date
from pathlib import Path
import sys
import unittest
from lxml import html
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tooling'))
from louisiana_draw_reports import parse_local_reports
FIXTURES = Path(__file__).resolve().parents[1] / 'fixtures/louisiana'


class LocalReportsTests(unittest.TestCase):
    def parse(self, raw, game='Lotto'):
        return parse_local_reports(raw, game, today=date(2026, 10, 13))

    def fixture(self, slug='lotto'):
        return (FIXTURES / (slug+'.html')).read_bytes()

    def test_bounded_literal_reports(self):
        for slug, game, size in [('lotto', 'Lotto', 6), ('easy-5', 'Easy 5', 5)]:
            reports = self.parse(self.fixture(slug), game)
            self.assertEqual([r['drawDate'] for r in reports], ['2026-10-10', '2026-10-07'])
            self.assertEqual(len(reports[0]['numbers']), size)
            self.assertEqual(len(reports[0]['tiers']), 4)
            self.assertEqual(reports[0]['tiers'][0]['prizeLabel'], 'Jackpot')
            self.assertEqual(reports[0]['sourceWarnings'], [])
        self.assertEqual(self.parse(self.fixture())[0]['tiers'][3]['winners'], 4526)
        self.assertEqual(self.parse(self.fixture())[0]['advertisedJackpot'], '$750,000')

    def test_rejects_malformed_source(self):
        raw = self.fixture()
        changes = [(b'<h1>Lotto', b'<h1>Easy 5'), (b'Saturday, October 10', b'Friday, October 10'),
                   (b'id="2026-10-07"', b'id="2026-10-10"'), (b'>02</li>', b'>99</li>'),
                   (b'>17</li>', b'>02</li>'), (b'4,526', b'-1'),
                   (b'<th>Winners</th>', b'<th>People</th>'), (b'>Jackpot</td>', b'>$0</td>'),
                   (b'Lotto numbers: 1 through 6', b'Lotto numbers: 1 through 5'),
                   (b'controls="section-lotto1"', b'controls="wrong"'),
                   (b'PM CDT', b'PM CST'), (b'</html>', b'')]
        for old, new in changes:
            with self.subTest(old=old):
                self.assertIn(old, raw)
                with self.assertRaises(ValueError): self.parse(raw.replace(old, new, 1))

    def test_missing_pair_and_extra_tier(self):
        for path in ['//table[@class="winning-numbers__table"]/tr[last()]', '//table[@class="table"]/tbody/tr[last()]']:
            root = html.fromstring(self.fixture()); node = root.xpath(path)[0];node.getparent().remove(node)
            with self.assertRaises(ValueError): self.parse(html.tostring(root))

    def test_all_rows_validated_before_bounding(self):
        root = html.fromstring(self.fixture());table=root.xpath('//table[@class="winning-numbers__table"]')[0]
        from copy import deepcopy
        for row in list(table.xpath('./tr'))[:2]:table.append(deepcopy(row))
        with self.assertRaises(ValueError): self.parse(html.tostring(root))

    def test_source_date_mismatch_retained_with_warning(self):
        raw=self.fixture().replace(b'10/10/2026 11:15:17 PM CDT',b'10/09/2026 11:15:17 PM CDT')
        report=self.parse(raw)[0]
        self.assertEqual(report['drawDate'],'2026-10-10')
        self.assertEqual(report['sourceUpdatedAt'],'2026-10-09T23:15:17-05:00')
        self.assertEqual(len(report['sourceWarnings']),1)

    def test_future_date_rejected(self):
        with self.assertRaises(ValueError): parse_local_reports(self.fixture(),'Lotto',today=date(2026,10,9))

if __name__ == '__main__': unittest.main()
