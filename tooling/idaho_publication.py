"""Continuity and atomic replacement for already validated Idaho collections."""
import copy
import json
import os
from pathlib import Path
import tempfile
from datetime import datetime
from tooling.idaho_coverage import collect
from tooling.idaho_retained_reports import check_report_provenance, retain_mfl_report


def _indexed(rows, key):
    result = {key(r):r for r in rows}
    if len(result) != len(rows): raise ValueError('Duplicate continuity identity')
    return result


def check_continuity(old, new):
    new = check_report_provenance(old, new)
    for field in ['schemaVersion','state','schedules','rules','sumSchedules','instantCatalogs','coverage']:
        if old[field] != new[field]: raise ValueError('Changed contract/catalog requires review: '+field)
    if datetime.fromisoformat(new['collectionStartedAt']) < datetime.fromisoformat(old['collectionStartedAt']):
        raise ValueError('Collection time regression')
    a = _indexed(old['results'], lambda r:(r['group'],r['drawDate']))
    b = _indexed(new['results'], lambda r:(r['group'],r['drawDate']))
    groups = {k[0] for k in a}
    if groups != {k[0] for k in b}: raise ValueError('Lost draw group')
    for g in groups:
        before = sorted(k[1] for k in a if k[0]==g)
        after = sorted(k[1] for k in b if k[0]==g)
        if len(before)!=2 or len(after)!=2 or any(y<x for x,y in zip(before,after)):
            raise ValueError('Draw window regression')
    for key in a.keys() & b.keys():
        before, after = copy.deepcopy(a[key]), copy.deepcopy(b[key])
        if before.get('report') is None and after.get('report') is not None:
            before['report'] = after['report']; before['reportGap'] = after['reportGap']
        if before != after: raise ValueError('Dated result/report correction or report loss')
    sa,sb = copy.deepcopy(old['scratch']),copy.deepcopy(new['scratch'])
    ga = _indexed(sa.pop('games'),lambda g:g['id'])
    gb = _indexed(sb.pop('games'),lambda g:g['id'])
    if sa != sb or ga.keys()!=gb.keys(): raise ValueError('Scratch identity/status change requires review')
    for gid in ga:
        before,after = copy.deepcopy(ga[gid]),copy.deepcopy(gb[gid])
        ta = before.pop('prizeTiers');tb = after.pop('prizeTiers')
        pa = before.pop('topPrizesRemaining');pb = after.pop('topPrizesRemaining')
        if before != after or type(pb) is not int or not 0<=pb<=pa:
            raise ValueError('Scratch structure/count regression')
        aa = _indexed(ta,lambda t:t['prizeAmount']);bb = _indexed(tb,lambda t:t['prizeAmount'])
        if aa.keys()!=bb.keys(): raise ValueError('Scratch tier loss')
        for amount in aa:
            x,y=copy.deepcopy(aa[amount]),copy.deepcopy(bb[amount]);xr=x.pop('remaining');yr=y.pop('remaining')
            if x!=y or type(yr) is not int or not 0<=yr<=xr: raise ValueError('Scratch count/structure correction')
    ra,rb=copy.deepcopy(old['raffle']),copy.deepcopy(new['raffle'])
    da=_indexed(ra.pop('dailyPromotions'),lambda r:r['date']);db=_indexed(rb.pop('dailyPromotions'),lambda r:r['date'])
    if ra!=rb or any(db.get(k)!=v for k,v in da.items()): raise ValueError('Raffle correction/loss')


def refresh(path, fetch, *, now=None):
    """Only collector-validated data reaches this single-file transaction."""
    path=Path(path)
    original=path.read_bytes() if path.exists() else None
    candidate=collect(fetch,now=now)
    if original is not None:
        old=json.loads(original)
        candidate=retain_mfl_report(old,candidate)
        check_continuity(old,candidate)
        a,b=copy.deepcopy(old),copy.deepcopy(candidate)
        for field in ['collectionStartedAt','sourceEvidence']:
            a.pop(field);b.pop(field)
        if a==b: return old
    encoded=(json.dumps(candidate,indent=2)+'\n').encode()
    temp=None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent,prefix=path.name+'.',suffix='.tmp',delete=False) as f:
            temp=Path(f.name);f.write(encoded);f.flush();os.fsync(f.fileno())
        # Avoid overwriting a concurrently changed snapshot.
        if (path.read_bytes() if path.exists() else None)!=original:
            raise ValueError('Snapshot changed during collection')
        os.replace(temp,path);temp=None
    finally:
        if temp is not None: temp.unlink(missing_ok=True)
    return candidate
