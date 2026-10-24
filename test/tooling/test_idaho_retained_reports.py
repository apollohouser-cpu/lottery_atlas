import copy
import unittest
from tooling.idaho_retained_reports import retain_mfl_report, SOURCE, GAP


def samples():
    row = dict(group='millionaire-for-life', drawDate='2026-10-22',
               sourceUrl=SOURCE, numbers=['01'], reportGap=None,
               report=dict(drawDate='2026-10-22', sourceUrl=SOURCE,
                           tiers=[dict(publishedWinnerCount=3)]))
    old = dict(results=[row], collectionStartedAt='2026-10-23T11:00:00+00:00',
               sourceEvidence=[dict(url=SOURCE, sha256='a'*64)])
    new = copy.deepcopy(old)
    new['collectionStartedAt'] = '2026-10-24T11:00:00+00:00'
    new['sourceEvidence'][0]['sha256'] = 'b'*64
    new['results'][0].update(report=None, reportGap=GAP)
    newer = copy.deepcopy(new['results'][0]);newer['drawDate']='2026-10-23'
    new['results'].append(newer)
    return old,new


class RetainedReportTest(unittest.TestCase):
    def test_retains_exact_bytes_and_original_provenance_without_mutating_inputs(self):
        old,new=samples(); before=copy.deepcopy(new)
        out=retain_mfl_report(old,new);r=out['results'][0]
        self.assertEqual(r['report'],old['results'][0]['report'])
        self.assertEqual(r['reportProvenance'],dict(collectionStartedAt=old['collectionStartedAt'],sourceUrl=SOURCE,sha256='a'*64))
        self.assertEqual(new,before)
        self.assertIsNone(out['results'][1]['report'])
        again=copy.deepcopy(new);again['collectionStartedAt']='2026-10-25T11:00:00+00:00'
        self.assertEqual(retain_mfl_report(out,again)['results'][0],r)

    def test_corrections_and_unproven_retention_rejected(self):
        for mutation in [lambda o,n:n['results'][0].update(numbers=['02']),
                         lambda o,n:n['results'][0].update(reportGap='network failure'),
                         lambda o,n:n['results'].pop(),
                         lambda o,n:o['sourceEvidence'].clear(),
                         lambda o,n:o['sourceEvidence'].append(o['sourceEvidence'][0]),
                         lambda o,n:o['sourceEvidence'][0].update(sha256='bad'),
                         lambda o,n:o.update(collectionStartedAt='2026-10-25T11:00:00+00:00'),
                         lambda o,n:o['results'][0]['report'].update(drawDate='2026-10-21')]:
            old,new=samples();mutation(old,new)
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):retain_mfl_report(old,new)

    def test_no_report_or_other_family_not_filled_and_current_report_not_overwritten(self):
        old,new=samples();old['results'][0]['report']=None
        self.assertEqual(retain_mfl_report(old,new),new)
        old,new=samples()
        for x in old['results']+new['results']:x['group']='powerball'
        self.assertEqual(retain_mfl_report(old,new),new)
        old,new=samples();new['results'][0]['report']={'changed':True}
        self.assertEqual(retain_mfl_report(old,new),new)

    def test_provenance_transition_is_bound_to_original_evidence(self):
        from tooling.idaho_retained_reports import check_report_provenance
        old,new=samples();out=retain_mfl_report(old,new)
        checked=check_report_provenance(old,out)
        self.assertNotIn('reportProvenance',checked['results'][0])
        self.assertEqual(checked['results'][0]['report'],old['results'][0]['report'])
        for mutation in [lambda x:x['results'][0]['reportProvenance'].update(sha256='b'*64),
                         lambda x:x['results'][0]['reportProvenance'].update(collectionStartedAt=new['collectionStartedAt']),
                         lambda x:x['results'][0]['report']['tiers'][0].update(publishedWinnerCount=4),
                         lambda x:x['results'][1].update(reportProvenance=out['results'][0]['reportProvenance'])]:
            bad=copy.deepcopy(out);mutation(bad)
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):check_report_provenance(old,bad)
        self.assertEqual(check_report_provenance(out,out),out)
        bad=copy.deepcopy(out);bad['results'][0]['reportProvenance']['sha256']='b'*64
        with self.assertRaises(ValueError):check_report_provenance(out,bad)
