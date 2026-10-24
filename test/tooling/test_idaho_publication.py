import copy
from datetime import datetime,timezone
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from tooling.idaho_publication import check_continuity,refresh


def sample():
    return dict(schemaVersion=1,state='Idaho',schedules={},rules={},sumSchedules={},instantCatalogs={},coverage='test',collectionStartedAt='2026-10-23T11:00:00+00:00',sourceEvidence=[],
        results=[dict(group='a',drawDate=d,report=None,reportGap='unavailable',numbers=[1]) for d in ['2026-10-21','2026-10-22']],
        scratch=dict(games=[dict(id='1',topPrizesRemaining=3,prizeTiers=[dict(prizeAmount=100,original=5,remaining=3)])],unavailableInventoryGames=[]),
        raffle=dict(dailyPromotions=[dict(date='2026-10-21',ticketNumber='012426')]))


class IdahoPublicationTest(unittest.TestCase):
    def test_refresh_retains_only_original_older_mfl_report_atomically(self):
        old=json.loads(Path('data/idaho_coverage.generated.json').read_text())
        new=copy.deepcopy(old)
        rows=[r for r in new['results'] if r['group']=='millionaire-for-life']
        latest=max(rows,key=lambda r:r['drawDate']);older=min(rows,key=lambda r:r['drawDate'])
        original_report=copy.deepcopy(latest['report'])
        from datetime import date,timedelta
        older['drawDate']=(date.fromisoformat(latest['drawDate'])+timedelta(days=1)).isoformat()
        older.update(report=None,reportGap='No exact-date Idaho HTML report available.')
        latest.update(report=None,reportGap='No exact-date Idaho HTML report available.')
        new['collectionStartedAt']='2026-10-25T11:00:00+00:00'
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'snapshot.json';original=json.dumps(old).encode();p.write_bytes(original)
            with patch('tooling.idaho_publication.collect',return_value=new),patch('tooling.idaho_publication.os.replace',side_effect=OSError('disk')):
                with self.assertRaises(OSError):refresh(p,None)
            self.assertEqual(p.read_bytes(),original)
            with patch('tooling.idaho_publication.collect',return_value=new):out=refresh(p,None)
            retained=next(r for r in out['results'] if r.get('reportProvenance'))
            self.assertEqual(retained['report'],original_report)
            self.assertEqual(retained['reportProvenance']['collectionStartedAt'],old['collectionStartedAt'])
            self.assertEqual(json.loads(p.read_bytes()),out)

    def test_supported_progression(self):
        old=sample();new=copy.deepcopy(old)
        new['results'][0]['drawDate']='2026-10-23'
        new['scratch']['games'][0]['topPrizesRemaining']=2
        new['scratch']['games'][0]['prizeTiers'][0]['remaining']=2
        new['raffle']['dailyPromotions'].append(dict(date='2026-10-22',ticketNumber='000001'))
        check_continuity(old,new)
        new=copy.deepcopy(old);new['results'][0].update(report={'tiers':[1]},reportGap=None)
        check_continuity(old,new)

    def test_corrections_and_losses_rejected(self):
        old=sample()
        for mutate in [lambda n:n['results'][0].update(numbers=[2]),lambda n:n['results'][0].update(drawDate='2026-10-20'),lambda n:n['scratch']['games'][0].update(topPrizesRemaining=4),lambda n:n['scratch']['games'][0]['prizeTiers'][0].update(remaining=4),lambda n:n['scratch']['games'].clear(),lambda n:n['raffle']['dailyPromotions'].clear(),lambda n:n.update(collectionStartedAt='2026-10-22T11:00:00+00:00')]:
            new=copy.deepcopy(old);mutate(new)
            with self.assertRaises(ValueError):check_continuity(old,new)

    def test_failures_preserve_exact_bytes_and_cleanup(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'snapshot.json';original=json.dumps(sample()).encode();p.write_bytes(original)
            with patch('tooling.idaho_publication.collect',side_effect=OSError('network')):
                with self.assertRaises(OSError):refresh(p,None)
            self.assertEqual(p.read_bytes(),original)
            new=sample();new['results'][0]['drawDate']='2026-10-23'
            with patch('tooling.idaho_publication.collect',return_value=new),patch('tooling.idaho_publication.os.replace',side_effect=OSError('disk')):
                with self.assertRaises(OSError):refresh(p,None)
            self.assertEqual(p.read_bytes(),original);self.assertEqual(list(Path(directory).glob('*.tmp')),[])

    def test_unchanged_preserves_date_bytes_and_success_replaces(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'snapshot.json';original=json.dumps(sample()).encode();p.write_bytes(original)
            new=sample();new['collectionStartedAt']='2026-10-23T12:00:00+00:00'
            with patch('tooling.idaho_publication.collect',return_value=new):refresh(p,None)
            self.assertEqual(p.read_bytes(),original)
            new['results'][0]['drawDate']='2026-10-23'
            with patch('tooling.idaho_publication.collect',return_value=new):refresh(p,None)
            self.assertEqual(json.loads(p.read_bytes()),new)
