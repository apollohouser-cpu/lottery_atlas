import json,unittest
from unittest.mock import patch
from tooling.montana_endings import parse_endings,SPEC_PATH
class EndingsTest(unittest.TestCase):
 def test_reviewed_rows_and_no_join(self):
  s=json.loads(SPEC_PATH.read_text());self.assertEqual(len(s['rows']),51)
  self.assertEqual(len({r['gameNumber'] for r in s['rows']}),51)
  self.assertTrue(all(r['salesStartDate']<r['salesEndDate']<r['lastRedemptionDate'] for r in s['rows']))
  self.assertEqual([r['gameNumber'] for r in s['rows'] if r['title']=='THE $30,000 MONTANA CROSSWORD'],['1355','1380'])
 def test_changed_bytes_rejected(self):
  with self.assertRaises(ValueError):parse_endings(b'%PDF changed',retrieved_at='2026-10-28T09:36:00Z')
 def test_timestamp_and_copy(self):
  import hashlib
  s=json.loads(SPEC_PATH.read_text());s['sha256']=hashlib.sha256(b'reviewed-test').hexdigest()
  with patch.object(type(SPEC_PATH),'read_text',return_value=json.dumps(s)):
   a=parse_endings(b'reviewed-test',retrieved_at='2026-10-28T09:36:00Z');a['rows'].clear()
   self.assertEqual(len(parse_endings(b'reviewed-test',retrieved_at='2026-10-28T09:36:00Z')['rows']),51)
   with self.assertRaises(ValueError):parse_endings(b'reviewed-test',retrieved_at='2026-10-28T09:36:00')
if __name__=='__main__':unittest.main()
