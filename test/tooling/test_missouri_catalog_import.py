import sys, tempfile, unittest
from pathlib import Path
from urllib.parse import parse_qs,urlparse
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
from import_missouri_scratch_catalog import SOURCE,refresh
from test_missouri_scratch_catalog import card,detail


def fake_fetch(url):
    if url==SOURCE:
        cards=''.join(card().replace('#569','#'+str(i))+f'<a href="scratchers.do?method=d&game={i}">Details</a>' for i in range(500,550))
        return ('<html><body><div class="scratchers-list_big-list">'+cards+'</div></body></html>').encode()
    gid=parse_qs(urlparse(url).query)['game'][0]
    return detail().replace('Game #569','Game #'+gid).encode()


class CatalogImportTests(unittest.TestCase):
    def test_full_snapshot_unchanged_dates_and_failure_retention(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t)/'catalog.json';r=refresh(p,fake_fetch);b=p.read_bytes()
            self.assertEqual(len(r['games']),50);self.assertIsNone(r['sourceDate'])
            refresh(p,fake_fetch);self.assertEqual(b,p.read_bytes())
            for broken_url in [SOURCE,'https://www.molottery.com/scratchers.do?method=d&game=520']:
                def fail(url):
                    if url==broken_url:raise ValueError('failed request')
                    return fake_fetch(url)
                with self.assertRaises(ValueError):refresh(p,fail)
                self.assertEqual(b,p.read_bytes())
            def partial(url):return fake_fetch(url).replace(b'</html>',b'')
            with self.assertRaises(ValueError):refresh(p,partial)
            self.assertEqual(b,p.read_bytes())

if __name__=='__main__':unittest.main()
