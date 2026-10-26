"""Collect coupled New Mexico coverage in memory; publication is a separate gate."""
from datetime import datetime, timedelta, timezone
import hashlib
import re
from urllib.parse import urlencode
from zoneinfo import ZoneInfo
from lxml import html
from tooling import import_new_mexico_draws as draws
from tooling import import_new_mexico_reports as reports
from tooling import import_new_mexico_scratch_catalog as scratch
from tooling.new_mexico_draw_rules import PAGES, parse_rules

REPORTS = [
    ('powerball','base',reports.PAIRED['powerball']['source'],reports.parse_paired_report),
    ('powerball','double_play',reports.DP_SOURCE,reports.parse_double_play),
    ('megamillions','base',reports.MM_SOURCE,reports.parse_mega_millions),
    ('lottoamerica','base',reports.PAIRED['lottoamerica']['source'],reports.parse_paired_report),
]
EXPECTED_GROUPS = {('powerball','base',None),('powerball','double_play',None),
                   ('megamillions','base',None),('lottoamerica','base',None),
                   ('roadrunnercash','base',None),('pick3plus','base','DAY'),
                   ('pick3plus','base','EVE'),('pick4plus','base','DAY'),('pick4plus','base','EVE')}


def report_date(raw):
    tree=html.fromstring(raw)
    text=' '.join(' '.join(n.text_content().split()) for n in tree.xpath('//h2|//p'))
    dates=re.findall(r'(?:Results for |prizes drawn on )([A-Za-z]+ [0-9]{1,2}, [0-9]{4})',text)
    if len(dates)!=1:
        raise ValueError('Missing/duplicate explicit report date')
    return datetime.strptime(dates[0],'%B %d, %Y').date().isoformat()


def collect(fetch, clock=lambda: datetime.now(timezone.utc)):
    sources=[]
    def get(url):
        raw=fetch(url);stamp=clock()
        if not isinstance(raw,bytes) or not raw or stamp.tzinfo is None:
            raise ValueError('Invalid capture or missing timezone')
        if sources and stamp<datetime.fromisoformat(sources[-1]['retrievedAt']):
            raise ValueError('Capture clock regression')
        sources.append(dict(url=url,retrievedAt=stamp.isoformat(),bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
        return raw,stamp
    start_clock=clock()
    if start_clock.tzinfo is None:
        raise ValueError('Missing collection timezone')
    today=start_clock.astimezone(ZoneInfo('America/Denver')).date()
    start=today-timedelta(days=14)
    results=[];rules=[]
    for game in draws.GAMES:
        query=urlencode(dict(game=game,start=start.strftime('%m/%d/%Y'),end=today.strftime('%m/%d/%Y'),sort='drawn',appmode='true',**{'seamless-embed':'true'}))
        url=draws.BASE+'search/?'+query
        raw,stamp=get(url)
        parsed=draws.parse_results(raw,game,start=start,end=today,today=today)
        for r in draws.latest_two(parsed):
            r.update(retrievedAt=stamp.isoformat(),sourceUrl=url,report=None)
            results.append(r)
        slug=PAGES[game][0]
        url=f'https://www.nmlottery.com/games/{slug}/how-to-play-{slug}/'
        raw,stamp=get(url);rule=parse_rules(raw,game);rule['retrievedAt']=stamp.isoformat();rules.append(rule)
    groups={(r['game'],r['variant'],r['session']) for r in results}
    if groups!=EXPECTED_GROUPS:
        raise ValueError('Missing current result group')
    for game,variant,url,parser in REPORTS:
        raw,stamp=get(url);day=report_date(raw)
        matched=[r for r in results if r['game']==game and r['variant']==variant and r['date']==day]
        if len(matched)!=1:
            raise ValueError('Latest report outside bounded result window')
        report=parser(raw,matched[0]);report['retrievedAt']=stamp.isoformat()
        matched[0].update(report=report,reportStatus='available')
    raw,stamp=get(scratch.INVENTORY);ending,end_stamp=get(scratch.ENDING)
    catalog=scratch.build_catalog(raw,ending,today)
    if len(catalog['games'])<20:
        raise ValueError('Unexpectedly small Scratch catalog')
    catalog.update(retrievedAt=stamp.isoformat(),endingRetrievedAt=end_stamp.isoformat())
    return dict(schemaVersion=1,state='New Mexico',updatedAt=sources[-1]['retrievedAt'],
                results=results,rules=rules,scratch=catalog,sources=sources,
                queryWindow=dict(start=start.isoformat(),end=today.isoformat(),timezone='America/Denver'),
                coverageNote='Latest two available dates per explicit group; exact-date New Mexico source Winners / prizes-won reports only. Missing reports unavailable, never zero. Estimated top-prize Scratch inventory, timezone unpublished. No complete history, claims, retailer joins, unique people/tickets or store stock.',
                unavailable=['Roadrunner Cash and Pick Plus exact-date winner reports','Historical and retired-game results/claims','Verified current Fast Play catalog and progressive values','Retailer-linked wins and complete statewide claims'])
