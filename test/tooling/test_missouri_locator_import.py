import json,sys,tempfile,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
from import_missouri_public_locator import refresh
from test_missouri_public_locator import RAW

class LocatorImportTests(unittest.TestCase):
    def test_atomic_failure_identity_and_unchanged_dates(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'local.json'
            result=refresh(p,'Test City',lambda city:RAW)
            before=p.read_bytes()
            self.assertIsNone(result['retailers'][0]['latitude'])
            self.assertEqual(result['query']['radiusMiles'],0)
            refresh(p,'Test City',lambda city:RAW)
            self.assertEqual(before,p.read_bytes())
            for f in [lambda city:RAW.replace(b'</html>',b''),lambda city:RAW.replace(b'65101',b'6510')]:
                with self.assertRaises(ValueError):refresh(p,'Test City',f)
                self.assertEqual(before,p.read_bytes())
            def fail(city):raise OSError('unavailable')
            with self.assertRaises(OSError):refresh(p,'Test City',fail)
            self.assertEqual(before,p.read_bytes())
            with self.assertRaises(ValueError):refresh(p,'Different City',lambda city:RAW)
            self.assertEqual(before,p.read_bytes())

if __name__=='__main__':unittest.main()
