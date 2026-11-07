"""Replay retained November opening evidence; private candidate, not a live feed."""
import argparse
from collections import defaultdict
from datetime import date, datetime
import hashlib
import json
from pathlib import Path
from tooling import delaware_ball_results as balls
from tooling import delaware_play_results as play
from tooling import delaware_powerball_results as powerball
from tooling import delaware_xsos_results as xsos
from tooling import delaware_keno_results as keno


def build(root):
    manifests = []
    for name in ['rules-history-manifest.json', 'xsos-manifest.json', 'previous-month-manifest.json', 'keno-query-manifest.json']:
        obj = json.loads((root/name).read_text())
        manifests.extend(obj if isinstance(obj,list) else [obj])
    by_url = {m['url']:m for m in manifests}
    if len(by_url) != len(manifests):
        raise ValueError('Ambiguous evidence URL')
    observations, evidence = [], []

    def read(url, filename):
        m = by_url[url]
        if m.get('file',filename) != filename or m.get('status',200) != 200:
            raise ValueError('Evidence file/status mismatch')
        raw = (root/filename).read_bytes()
        if len(raw) != m['bytes'] or hashlib.sha256(raw).hexdigest() != m['sha256']:
            raise ValueError('Evidence bytes changed')
        provenance = {k:m[k] for k in ['url','retrievedAt','bytes','sha256']}
        evidence.append(provenance)
        return raw, datetime.fromisoformat(m['retrievedAt']).date(), provenance

    def append(parsed, provenance):
        for row in parsed['results']:
            observations.append(dict(row, game=row.get('game',parsed.get('game')),
                                     provenance=provenance, coverage=parsed.get('coverage','Observed monthly source rows only; no complete-history claim.')))

    for game,month in [('Play3',11),('Play4',11),('Play5',11),('PowerBall',11),('MultiWin',11),('LottoAmerica',11),('MegaMillions',11),('MegaMillions',10),('PowerballXsAndOs',11),('PowerballXsAndOs',10)]:
        url=f'https://www.delottery.com/Winning-Numbers/Search-Winners/2026/{month}/{game}'
        filename=(f'xsos-{"november" if month==11 else "october"}.html' if game=='PowerballXsAndOs' else f'Winning-Numbers_Search-Winners_2026_{month}_{game}.html')
        raw,observed,provenance=read(url,filename)
        kwargs=dict(year=2026,month=month,source_url=url,observed_date=observed)
        if game.startswith('Play'): parsed=play.parse(raw,digits=int(game[-1]),**kwargs)
        elif game=='PowerBall': parsed=powerball.parse(raw,**kwargs)
        elif game=='PowerballXsAndOs': parsed=xsos.parse(raw,**kwargs)
        else: parsed=balls.parse(raw,game=game,**kwargs)
        append(parsed,provenance)
    raw,observed,provenance=read(keno.SOURCE,'keno-by-date-20261105.html')
    append(keno.parse(raw,source_url=keno.SOURCE,requested_date=date(2026,11,5),observed_date=observed),provenance)
    groups=defaultdict(list);seen=set()
    for row in observations:
        key=(row['game'],row.get('session',''))
        identity=key+(row['drawDate'],row.get('gameNumber',''))
        if identity in seen:raise ValueError('Duplicate observation across sources')
        seen.add(identity);groups[key].append(row)
    if len(groups)!=13:raise ValueError('Opening scope group mismatch')
    selected=[]
    for key,rows in sorted(groups.items()):
        rows.sort(key=lambda r:(r['drawDate'],int(r.get('gameNumber',0))),reverse=True)
        if len(rows)<2:raise ValueError('Latest-two opening target not met')
        selected.extend(rows[:2])
    return {'state':'Delaware','status':'private development candidate; not accepted or published',
            'observedRows':len(observations),'selectedRows':len(selected),'groups':len(groups),
            'results':selected,'evidence':evidence,
            'coverage':'Latest two within retained opening captures only, not current live freshness or full history. Dates/times retain source semantics; no synthetic timezone or winners.'}


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--evidence',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    result=build(a.evidence)
    with a.output.open('x') as f:json.dump(result,f,indent=2);f.write('\n')
    print({k:result[k] for k in ['observedRows','selectedRows','groups']})
