import unittest
from unittest.mock import patch
import hashlib
from tooling.iowa_schedules import verified_chart

class IowaScheduleTest(unittest.TestCase):
    def test_unreviewed_change_rejected(self):
        with self.assertRaisesRegex(ValueError,'review required'):
            verified_chart('Pick3',b'new chart')
    def test_unknown_chart_rejected(self):
        with self.assertRaises(ValueError):verified_chart('Unknown',b'image')
    def test_exact_reviewed_bytes_and_defensive_copy(self):
        spec={'game':'test','sha256':hashlib.sha256(b'image').hexdigest(),'rows':[{'prizes':['N/A','$600']}]}
        with patch('tooling.iowa_schedules.SPECS',[spec]):
            result=verified_chart('test',b'image');result['rows'][0]['prizes'][0]='bad'
            self.assertEqual(verified_chart('test',b'image')['rows'][0]['prizes'][0],'N/A')
