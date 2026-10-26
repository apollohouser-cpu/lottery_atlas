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


def continuity(prior, candidate):
    """Reject corrections/regressions; retain older exact-date report provenance."""
    from copy import deepcopy
    def without(value, *keys):
        return {k:v for k,v in value.items() if k not in keys}
    if (prior['schemaVersion'], prior['state']) != (candidate['schemaVersion'], candidate['state']):
        raise ValueError('Coverage identity changed')
    if datetime.fromisoformat(candidate['updatedAt']) < datetime.fromisoformat(prior['updatedAt']):
        raise ValueError('Collection date regressed')
    if any(candidate['queryWindow'][k] < prior['queryWindow'][k] for k in ('start','end')):
        raise ValueError('Query window regressed')
    if [without(r,'retrievedAt') for r in prior['rules']] != [without(r,'retrievedAt') for r in candidate['rules']]:
        raise ValueError('Rule contract changed')
    def keyed(rows):
        result={}
        for row in rows:
            key=(row['game'],row['variant'],row['session'],row['date'])
            if key in result: raise ValueError('Duplicate result identity')
            result[key]=row
        return result
    old=keyed(prior['results']);new=keyed(candidate['results'])
    retained=[]
    for group in EXPECTED_GROUPS:
        before=sorted(k[3] for k in old if k[:3]==group)
        after=sorted(k[3] for k in new if k[:3]==group)
        if not before or not after or len(after)<len(before) or after[0]<before[0] or after[-1]<before[-1]:
            raise ValueError('Result window regressed')
        if any(k[:3]==group and k not in new and k[3]>=after[0] for k in old):
            raise ValueError('Result identity lost within window')
    for key in old.keys() & new.keys():
        a,b=old[key],new[key]
        dynamic=('retrievedAt','sourceUrl','report','reportStatus')
        if without(a,*dynamic)!=without(b,*dynamic):
            raise ValueError('Published result corrected')
        if a['report'] is not None:
            if b['report'] is not None:
                if without(a['report'],'retrievedAt')!=without(b['report'],'retrievedAt'):
                    raise ValueError('Published report corrected')
            else:
                b.update(report=deepcopy(a['report']),reportStatus='available')
                source=[s for s in prior['sources']+prior.get('retainedReportSources',[])
                        if s['url']==a['report']['sourceUrl'] and s['retrievedAt']==a['report']['retrievedAt']]
                if not source: raise ValueError('Retained report provenance missing')
                retained.append(deepcopy(source[0]))
    candidate['retainedReportSources']=retained
    a,b=prior['scratch'],candidate['scratch']
    if (b['sourceDate']<a['sourceDate'] or
        datetime.strptime(b['sourceTimestamp'],'%B %d, %Y %I:%M %p') <
        datetime.strptime(a['sourceTimestamp'],'%B %d, %Y %I:%M %p')):
        raise ValueError('Scratch source date regressed')
    for field in ('state','source','inventorySource','endingSource','sourceTimezone','coverage','updateCadence'):
        if a[field]!=b[field]: raise ValueError('Scratch semantics changed')
    def games(catalog):
        values={g['id']:g for g in catalog['games']}
        if len(values)!=len(catalog['games']): raise ValueError('Duplicate Scratch identity')
        return values
    before,after=games(a),games(b)
    if after.keys()-before.keys(): raise ValueError('Unreviewed new Scratch identity')
    for identity,game in before.items():
        if identity not in after:
            deadline=game.get('lastDayToRedeem')
            if not deadline or deadline>=candidate['queryWindow']['end'] or identity not in b['excludedExpiredGameIds']:
                raise ValueError('Scratch identity lost without expired claim deadline')
            continue
        other=after[identity]
        if without(game,'topPrizesRemaining','inventoryNote')!=without(other,'topPrizesRemaining','inventoryNote'):
            raise ValueError('Scratch metadata changed')
        if other['topPrizesRemaining']>game['topPrizesRemaining']:
            raise ValueError('Estimated top prizes increased')
    return candidate


def refresh(path, fetch, clock=lambda: datetime.now(timezone.utc)):
    """Persist only a complete validated collection, replacing bytes atomically."""
    import json
    import os
    from pathlib import Path
    import tempfile
    path=Path(path)
    prior=json.loads(path.read_text()) if path.exists() else None
    candidate=collect(fetch,clock)
    if prior is not None: continuity(prior,candidate)
    encoded=(json.dumps(candidate,ensure_ascii=False,indent=2)+'\n').encode()
    temporary=None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent,prefix=path.name+'.',delete=False) as handle:
            temporary=handle.name
            handle.write(encoded);handle.flush();os.fsync(handle.fileno())
        os.replace(temporary,path)
    finally:
        if temporary and os.path.exists(temporary): os.unlink(temporary)
    return candidate
