import copy
import unittest
from tooling.delaware_instant_instructions import compose


class InstructionContinuityTest(unittest.TestCase):
    def setUp(self):
        self.images = [{'gameId': '501', 'names': ['SOURCE TITLE'], 'sourceUrl': 'https://example.test/501.jpg',
                        'retrievedAt': '2026-11-07T13:00:00+00:00', 'sha256': 'a'*64}]
        self.index = {'completeInstructionScreen': True, 'completeTierAudit': False, 'count': 1,
                      'reviewedAt': '2026-11-08T13:00:00+00:00', 'entries': [{
                          'gameId': '501', 'sourceUrl': self.images[0]['sourceUrl'],
                          'sourceRetrievedAt': self.images[0]['retrievedAt'], 'sourceSha256': 'a'*64,
                          'instructionSummary': 'Match numbers.', 'boundary': 'Ordered-ticket structure only.',
                          'review': 'Partial tiers.', 'valuationCaveat': 'Source valuation differs.',
                          'printedPrizeTotal': 123, 'tiers': [{'unreviewed': True}]}]}

    def test_does_not_promote_counts_tiers_or_invent_title(self):
        item = compose(self.index, self.images)[0]
        self.assertEqual(item['names'], ['SOURCE TITLE'])
        self.assertEqual(item['qualifications'], ['Source valuation differs.'])
        self.assertEqual(item['tierCoverage'], 'not-complete')
        self.assertNotIn('tiers', item)
        self.assertNotIn('printedPrizeTotal', item)

    def test_changed_provenance_empty_summary_unknown_identity_rejected(self):
        for key, value in [('sourceUrl','other'), ('sourceSha256','b'*64),
                           ('sourceRetrievedAt','2026-11-08T13:00:00+00:00'),
                           ('instructionSummary',' '), ('gameId','999')]:
            index = copy.deepcopy(self.index); index['entries'][0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError): compose(index,self.images)

    def test_incomplete_duplicate_scope_or_time_rejected(self):
        variants = []
        for key,value in [('completeTierAudit',True),('count',2),
                          ('reviewedAt','2026-11-06T13:00:00+00:00'),
                          ('reviewedAt','2026-11-08T13:00:00')]:
            index=copy.deepcopy(self.index);index[key]=value;variants.append(index)
        empty=copy.deepcopy(self.index);empty.update(entries=[],count=0);variants.append(empty)
        dup=copy.deepcopy(self.index);dup['entries']*=2;dup['count']=2;variants.append(dup)
        for index in variants:
            with self.assertRaises(ValueError): compose(index,self.images)
