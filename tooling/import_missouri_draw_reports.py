"""Bounded all-family Missouri report refresh; replace output only after validation."""
import argparse
from datetime import date, datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
from zoneinfo import ZoneInfo
from urllib.parse import urljoin, urlparse, parse_qs, urlencode
from lxml import html
from missouri_draw_reports import (parse_powerball, parse_powerball_xo, parse_mega_millions,
    parse_mo_millions, parse_show_me_cash, parse_pick, parse_cash_pop)

ROOT = 'https://www.molottery.com/'
FAMILIES = ['powerball', 'powerballxo', 'mega-millions', 'mo-millions', 'show-me-cash', 'pick3', 'pick4', 'cash-pop']


def fetch(url, form=None):
    cmd = ['curl', '-fsSL', '--max-time', '40', '-H', 'Accept-Language: en-US,en;q=0.9']
    if form is not None:
        cmd += ['--data', urlencode(form)]
    return subprocess.check_output(cmd+[url])


def sessions(family):
    return ['Midday', 'Evening'] if family in ('pick3', 'pick4') else list('12345') if family == 'cash-pop' else ['draw']


def links(raw, family, today):
    if b'</html>' not in raw.lower():
        raise ValueError('Incomplete history document')
    result = {}
    for href in html.fromstring(raw).xpath('//a/@href'):
        if 'prizes-paid.do?' not in href:
            continue
        url = urljoin(ROOT+family+'/', href.strip())
        u = urlparse(url)
        if u.netloc != 'www.molottery.com' or u.scheme != 'https' or u.path != '/'+family+'/prizes-paid.do':
            raise ValueError('Unexpected report route')
        q = parse_qs(u.query)
        key = 'time' if family in ('pick3','pick4') else 'type' if family == 'cash-pop' else None
        if set(q) != ({'date', key} if key else {'date'}) or any(len(v)!=1 for v in q.values()):
            raise ValueError('Changed report query')
        day = date.fromisoformat(q['date'][0].strip())
        session = q[key][0] if key else 'draw'
        if session not in sessions(family):
            raise ValueError('Unknown report session')
        if day > today:
            raise ValueError('Future report date')
        if day < today-timedelta(days=40):
            continue
        # Cash Pop date-first URLs have returned the wrong session; type-first
        # was verified against printed date/session. Keep strict parser checks.
        query = ({key:session, 'date':day.isoformat()} if family == 'cash-pop'
                 else {'date':day.isoformat(), **({key:session} if key else {})})
        canonical = ROOT+family+'/prizes-paid.do?'+urlencode(query)
        identity = (session,day.isoformat())
        result[identity] = canonical  # repeated same source link is harmless
    return result


def parse(family, raw, day, session):
    if family in ('pick3','pick4'):
        return parse_pick(raw, day, int(family[-1]), session)
    if family == 'cash-pop':
        return parse_cash_pop(raw, day, int(session))
    return dict(zip(FAMILIES[:5], [parse_powerball,parse_powerball_xo,parse_mega_millions,parse_mo_millions,parse_show_me_cash]))[family](raw,day)


def build(fetcher=fetch, today=None, parser=parse):
    today = today or datetime.now(ZoneInfo("America/Chicago")).date()
    reports = []
    for family in FAMILIES:
        url = ROOT+family+'/winning-numbers.do'
        found = links(fetcher(url), family, today)
        if any(sum(s==session for s,d in found)<2 for session in sessions(family)):
            previous = today.replace(day=1)-timedelta(days=1)
            found.update(links(fetcher(url, {'ddMonth':previous.month,'ddYear':previous.year}),family,today))
        for session in sessions(family):
            chosen = sorted([(d,u) for (s,d),u in found.items() if s==session],reverse=True)[:2]
            if len(chosen)!=2:
                raise ValueError('Insufficient report continuity: '+family+'/'+session)
            for day, source in chosen:
                report = parser(family,fetcher(source),day,session)
                if report.get('drawDate') != day:
                    raise ValueError('Parsed report date differs')
                reports.append(dict(report, family=family, sessionKey=session, sourceUrl=source))
    return dict(stateCode='MO', reports=reports,
                coverage='Two latest linked reports per game/session within 40 days, using current and at most one prior calendar month. Published reports are not certified final. Source units and unavailable values retained.')


def validate_continuity(new, old):
    def dates(payload):
        groups = {}
        for r in payload['reports']:
            key = (r['family'],r['sessionKey'])
            if key not in [(f,s) for f in FAMILIES for s in sessions(f)]:
                raise ValueError('Unknown report group')
            d = date.fromisoformat(r['drawDate'])
            if d in groups.setdefault(key,[]):
                raise ValueError('Duplicate report identity')
            groups[key].append(d)
        expected = {(f,s) for f in FAMILIES for s in sessions(f)}
        if set(groups)!=expected or any(len(v)!=2 for v in groups.values()):
            raise ValueError('Incomplete report groups')
        return {k:sorted(v,reverse=True) for k,v in groups.items()}
    current = dates(new)
    if old is not None:
        prior = dates(old)
        if any(any(a<b for a,b in zip(current[k],v)) for k,v in prior.items()):
            raise ValueError('Report date regression')


def refresh(output, fetcher=fetch, today=None, parser=parse):
    output = Path(output)
    old = json.loads(output.read_text()) if output.exists() else None
    new = build(fetcher,today,parser)
    validate_continuity(new,old)
    if old and old.get('reports') == new['reports'] and old.get('coverage') == new['coverage']:
        return old
    new['updatedAt'] = datetime.now(timezone.utc).isoformat()
    output.parent.mkdir(parents=True,exist_ok=True)
    temporary = output.with_suffix(output.suffix+'.tmp')
    temporary.write_text(json.dumps(new,indent=2)+'\n')
    temporary.replace(output)
    return new


if __name__ == '__main__':
    args = argparse.ArgumentParser()
    args.add_argument('--output',required=True)
    opts = args.parse_args()
    r = refresh(opts.output)
    print('Validated Missouri reports:',len(r['reports']))
