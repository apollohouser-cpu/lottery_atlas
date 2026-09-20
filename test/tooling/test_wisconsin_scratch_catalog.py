import importlib.util
from datetime import date
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('wi',Path(__file__).resolve().parents[2]/'tooling/import_wisconsin_scratch_catalog.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
TODAY=date(2026,9,20)
LISTING=dict(url=m.SOURCE.rsplit('/',1)[0]+'/example-123',name='Example',start='2026-01-01',end=None,cost=5,prizeLabel='Top Instant Prize $50,000!')

def detail(extra='',remaining='2',total='3'):
    fields={'Game Number':'123','Price':'$5.00','Start Date':'01/01/2026'}
    if remaining is not None: fields.update({'Total Top Prizes':total,'Remaining Top Prizes':remaining})
    return ''.join(f'<div class="instant-row"><div class="cell">{k}</div><div class="cell">{v}</div></div>' for k,v in fields.items())+extra+'<p>Top prize counts verified weekly</p>'

def listing_page(rows,links=''):
    return ''.join(f'<div class="instant-listing-item" data-type="{kind}" data-startd="2026-01-01" data-endd="" data-price="5.00"><a href="/games/instant-games/example-{gid}"></a><h3>Example</h3><div class="top-prize-amount">Top Prize $50,000!</div></div>' for kind,gid in rows)+f'<nav class="pager">{links}</nav>'

class WisconsinTest(unittest.TestCase):
    def test_instant_tier_and_counts(self):
        g=m.parse_detail(detail(),LISTING,TODAY)
        self.assertEqual(g['topPrizeLabel'],'$50,000 instant prize')
        self.assertEqual(g['topPrizesRemaining'],2)
        self.assertIn('verification date unpublished',g['inventoryNote'])

    def test_source_paragraph_inside_heading_keeps_game_name(self):
        raw=listing_page([('scratch','123')]).replace('<h3>Example</h3>','<h3><p>Example</p></h3>')
        rows,_=m.parse_listing(raw)
        self.assertEqual(rows[0]['name'],'Example')
        game=m.parse_detail('<h1><p>Example</p></h1>'+detail(),rows[0],TODAY)
        self.assertEqual(game['name'],'Example')

    def test_missing_counts_are_unknown(self):
        g=m.parse_detail(detail(remaining=None),LISTING,TODAY)
        self.assertNotIn('topPrizesRemaining',g)
        self.assertIn('Remaining count unavailable',g['inventoryNote'])

    def test_expired_detail_overrides_blank_listing_date(self):
        expired='<div class="instant-row"><div class="cell">Redeem By</div><div class="cell">09/19/2026</div></div>'
        self.assertIsNone(m.parse_detail(detail(expired),LISTING,TODAY))
        same_day=expired.replace('09/19/2026','09/20/2026')
        self.assertEqual(m.parse_detail(detail(same_day),LISTING,TODAY)['lastDayToRedeem'],'2026-09-20')

    def test_inconsistent_identity_and_counts_rejected(self):
        for raw in [detail().replace('123','999'), detail().replace('$5.00','$10.00'),detail(remaining='4'),detail(remaining='-1'),detail().replace('01/01/2026','01/02/2026')]:
            with self.subTest(raw=raw):
                with self.assertRaises(ValueError):m.parse_detail(raw,LISTING,TODAY)

    def test_filters_pulltabs_and_validates_pagination(self):
        rows,pages=m.parse_listing(listing_page([('scratch','123'),('pulltab','456')],'<a href="?page=1">Next</a>'))
        self.assertEqual(len(rows),1);self.assertEqual(pages,{1})
        with self.assertRaises(ValueError):m.parse_listing(listing_page([('scratch','123')],'<a href="https://other.example/?page=1">Next</a>'))

    def test_identical_page_overlap_deduplicated(self):
        pages={m.SOURCE+'?page=0':listing_page([('scratch','123')],'<a href="?page=1">Next</a>'),m.SOURCE+'?page=1':listing_page([('scratch','123')]),LISTING['url']:detail()}
        catalog=m.build_catalog(pages.__getitem__,TODAY)
        self.assertEqual(len(catalog['games']),1)
        self.assertEqual(catalog['listingPageCount'],2)
        pages[m.SOURCE+'?page=1']=pages[m.SOURCE+'?page=1'].replace('Top Prize $50,000!','Top Prize $20,000!')
        with self.assertRaises(ValueError):m.build_catalog(pages.__getitem__,TODAY)

if __name__=='__main__':unittest.main()
