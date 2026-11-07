"""Compose audited opening rule evidence without updating public data or dates."""
import argparse
import hashlib
import json
from pathlib import Path
from tooling import delaware_xsos_rules as xsos
from tooling import delaware_multiwin_rules as multiwin
from tooling import delaware_powerball_rules as powerball
from tooling import delaware_megamillions_rules as mega
from tooling import delaware_keno_rules as keno
from tooling import delaware_lottoamerica_rules as lotto
from tooling import delaware_play_chart_rules as play
from tooling import delaware_luckyforlife_rules as legacy


def build(root):
    entries=[]
    for name in ['rules-history-manifest.json','linked-manifest.json','rule-charts-manifest.json']:
        entries.extend(json.loads((root/name).read_text()))
    by_file={m['file']:m for m in entries}
    if len(by_file)!=len(entries):raise ValueError('Ambiguous rule evidence file')

    def read(filename):
        m=by_file[filename];raw=(root/filename).read_bytes()
        if m['status']!=200 or len(raw)!=m['bytes'] or hashlib.sha256(raw).hexdigest()!=m['sha256']:
            raise ValueError('Rule evidence changed or failed')
        return raw,{k:m[k] for k in ['url','retrievedAt','bytes','sha256']}

    rules=[]
    for slug,module in [('Powerball-Xs-And-Os',xsos),('Multi-Win-Lotto',multiwin),('Powerball',powerball),('Mega-Millions',mega),('Keno',keno)]:
        filename='Keno_Prizes-And-Odds.html' if slug=='Keno' else f'Drawing-Games_{slug}_Prizes-And-Odds.html'
        raw,provenance=read(filename)
        rules.append({'family':slug,'status':'current supported target','rule':module.parse(raw,source_url=provenance['url']),'evidence':[provenance]})
    raw,page=read('Drawing-Games_Lotto-America_Prizes-And-Odds.html');image,chart=read('chart-Lotto-America.jpg')
    rules.append({'family':'Lotto-America','status':'current supported target','rule':lotto.parse(raw,image,source_url=page['url'],chart_url=chart['url']),'evidence':[page,chart]})
    for digits in (3,4,5):
        _,page=read(f'Drawing-Games_Play-{digits}_Prizes-And-Odds.html');image,chart=read(f'chart-Play-{digits}.jpg')
        rules.append({'family':f'Play-{digits}','status':'current supported target','rule':play.parse(image,chart_url=chart['url'],digits=digits),'evidence':[page,chart]})
    _,page=read('Drawing-Games_Lucky-For-Life_Prizes-And-Odds.html');image,chart=read('chart-Lucky-For-Life.jpg')
    rules.append({'family':'Lucky-For-Life','status':'historical/legacy','rule':legacy.parse(image,chart_url=chart['url']),'evidence':[page,chart]})
    return {'state':'Delaware','status':'private development candidate; not published or accepted','families':len(rules),'rules':rules,'coverage':'Opening prize schedules and qualifications only; source-specific collection dates preserved. Full how-to-play/link integration remains separate. Source inconsistencies are not resolved by composition.'}


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--evidence',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    result=build(a.evidence)
    with a.output.open('x') as f:json.dump(result,f,indent=2);f.write('\n')
    print(f"Validated {result['families']} rule families with source evidence.")
