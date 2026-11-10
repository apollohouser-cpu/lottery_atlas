import copy
import unittest
from tooling.delaware_product_details import compose


class ProductDetailsTest(unittest.TestCase):
    def setUp(self):
        self.images = [dict(gameId=g, sourceUrl='https://example.test/'+g,
                            sha256=g*64, retrievedAt='2026-11-07T13:00:00+00:00')
                       for g in ('1', '2')]
        self.products = {'games': [dict(id=x['gameId'], detailImage=x['sourceUrl'],
                                       topPrizesRemaining=0, topPrize=1000000)
                                  for x in self.images]}
        self.guides = [dict(gameId=x['gameId'], sourceUrl=x['sourceUrl'],
                            sourceSha256=x['sha256'], sourceRetrievedAt=x['retrievedAt'],
                            tierCoverage='not-complete', instructionSummary='Match symbols.')
                       for x in self.images]
        self.tiers = [dict(self.guides[0], totalCount=99, totalValue=640000)]
        self.exclusions = [dict(self.guides[1], reason='Printed value conflicts.', status='excluded')]

    def run_compose(self):
        return compose(self.products, self.images, self.guides, self.tiers, self.exclusions)

    def test_inventory_printed_runs_and_exclusions_remain_distinct(self):
        details = self.run_compose()
        self.assertEqual(details[0]['product']['topPrizesRemaining'], 0)
        self.assertEqual(details[0]['product']['topPrize'], 1000000)
        self.assertEqual(details[0]['prizeStructure']['totalValue'], 640000)
        self.assertEqual(details[0]['prizeStructureStatus'], 'reviewed')
        self.assertNotIn('tierCoverage', details[0]['instructions'])
        self.assertEqual(details[1]['prizeStructureStatus'], 'excluded')
        self.assertIsNone(details[1]['prizeStructure'])
        self.assertEqual(details[1]['prizeStructureExclusion']['reason'], 'Printed value conflicts.')
        self.assertFalse(details[0]['actualClaimsAvailable'])
        details[0]['product']['topPrizesRemaining'] = 5
        self.assertEqual(self.products['games'][0]['topPrizesRemaining'], 0)

    def test_missing_duplicate_overlapping_or_unknown_identity_rejected(self):
        for attr in ('products', 'images', 'guides', 'tiers', 'exclusions'):
            original = copy.deepcopy(getattr(self, attr))
            rows = self.products['games'] if attr == 'products' else getattr(self, attr)
            saved = rows.pop()
            with self.subTest(attr=attr, mode='missing'), self.assertRaises(ValueError):
                self.run_compose()
            rows.extend([saved, saved])
            with self.subTest(attr=attr, mode='duplicate'), self.assertRaises(ValueError):
                self.run_compose()
            setattr(self, attr, original)
        self.exclusions.append(self.tiers[0])
        with self.assertRaises(ValueError): self.run_compose()

    def test_changed_source_dates_urls_or_hashes_rejected(self):
        for attr in ('guides', 'tiers', 'exclusions'):
            for key in ('sourceUrl', 'sourceSha256', 'sourceRetrievedAt'):
                original = copy.deepcopy(getattr(self, attr))
                getattr(self, attr)[0][key] = 'changed'
                with self.subTest(attr=attr, key=key), self.assertRaises(ValueError):
                    self.run_compose()
                setattr(self, attr, original)
        self.products['games'][0]['detailImage'] = 'changed'
        with self.assertRaises(ValueError): self.run_compose()


if __name__ == '__main__': unittest.main()
