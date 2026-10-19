from datetime import date
import unittest
from tooling.iowa_instant_inventories import parse_inventories


def fixture():
    headers = ['Game Name (Game Number)', 'Game Type', 'Cost', 'Prize', 'Claimed', 'Unclaimed']
    rows = ''.join('<tr>'+''.join('<td>'+v+'</td>' for v in ['GAME (1)', kind, '1', '$50', '2', '0'])+'</tr>' for kind in ['Scratch', 'InstaPlay', 'PullTab'])
    return '<span id="ContentPlaceHolder1_DataAsOf">10/17/2026</span><table id="RemainPrizes_JS_DATATABLE"><thead><tr>'+''.join('<th>'+h+'</th>' for h in headers)+'</tr></thead><tbody>'+rows+'</tbody></table>'


class TypedInventoriesTest(unittest.TestCase):
    def parse(self, raw):
        return parse_inventories(raw, as_of=date(2026,10,19))

    def test_same_id_in_three_types_remains_distinct(self):
        result = self.parse(fixture())
        self.assertEqual(len(result['inventories']), 3)
        for subset in result['inventories']:
            game = subset['games'][0]
            self.assertEqual(game['productType'], subset['productType'])
            self.assertNotIn('topPrize', game)
            self.assertEqual(game['prizeTiers'][0]['unclaimed'], 0)

    def test_all_types_validated_not_silently_skipped(self):
        for before, after in [('InstaPlay','Unknown'), ('$50','$49'), ('<td>2</td>','<td>-1</td>'), ('<td>0</td>','<td>?</td>'), ('10/17/2026','10/20/2026')]:
            with self.assertRaises(ValueError): self.parse(fixture().replace(before, after))

    def test_missing_subset_duplicate_tier_and_conflicting_identity(self):
        raw = fixture()
        start = raw.index('<tbody>') + len('<tbody>')
        end = raw.index('</tr>', start) + len('</tr>')
        row = raw[start:end]
        for changed in [raw[:start]+raw[end:], raw.replace('</tbody>',row+'</tbody>'), raw.replace('</tbody>',row.replace('GAME (1)','OTHER (1)').replace('$50','$100')+'</tbody>')]:
            with self.assertRaises(ValueError): self.parse(changed)

    def test_source_schema_and_date_required(self):
        for changed in [fixture().replace('Claimed</th>','Paid</th>'), fixture().replace('10/17/2026','unknown'), fixture()+fixture()]:
            with self.assertRaises(ValueError): self.parse(changed)
