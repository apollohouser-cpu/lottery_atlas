"""Literal ending notices; never calculate redemption deadlines from end dates."""
import copy
import re
from datetime import datetime

LABELS = {'scratchers': 'Last Day to Claim Prizes', 'fast-play': 'Game End Date'}
CONFLICT = ('Fast Play visible column says Game End Date, while accessibility '
            'description calls the dates claim deadlines and surrounding prose '
            'uses ticket purchase date. No normalized claim deadline is inferred.')


def parse_capture(capture, kind):
    if kind not in LABELS:
        raise ValueError('unknown ending family')
    root = 'https://www.arizonalottery.com/' + kind + '/'
    if set(capture) != {'sourceUrl','captureKind','retrievedAt','tables'} or capture['sourceUrl'] != root or capture['captureKind'] != 'browser-dom-ending-observation':
        raise ValueError('ending provenance changed')
    if datetime.fromisoformat(capture['retrievedAt'].replace('Z','+00:00')).tzinfo is None:
        raise ValueError('acquisition timezone required')
    tables = capture['tables']
    if len(tables) != 1 or tables[0]['id'] != 'ended-games':
        raise ValueError('one ending table required')
    rows = tables[0]['rows']
    header = [{'text':'Ended Games','links':[]},{'text':LABELS[kind],'links':[]}]
    footer = [{'text':'','links':[{'text':label,'href':root+'#'}]} for label in ('See All','Expand menu to see more ended games')]
    if len(rows)<3 or rows[0]!=header or rows[-1]!=footer:
        raise ValueError('ending table boundary changed or not expanded')
    result=[]; seen=set()
    for row in rows[1:-1]:
        if len(row)!=2 or set(row[0])!={'text','links'} or set(row[1])!={'text','links'} or row[1]['links']:
            raise ValueError('invalid ending row')
        match=re.fullmatch(r'(.+) #([0-9]+)',row[0]['text'])
        if not match or match[2] in seen or len(row[0]['links'])!=1:
            raise ValueError('missing or duplicate ending identity')
        title,number=match.groups();link=row[0]['links'][0]
        if set(link)!={'text','href'} or link['text']!=row[0]['text'] or not re.fullmatch(re.escape(root+number)+r'-[a-z0-9-]+/',link['href']):
            raise ValueError('ending source/identity mismatch')
        date=row[1]['text']
        if not re.fullmatch(r'\d{1,2}/\d{1,2}/\d{4}',date):
            raise ValueError('invalid notice date')
        datetime.strptime(date,'%m/%d/%Y')
        seen.add(number)
        result.append(dict(gameNumber=number,title=title,sourceUrl=link['href'],
                           dateLabel=LABELS[kind],dateText=date,
                           claimDeadlineNormalized=False,inventoryAvailable=False))
    return dict(sourceUrl=root,retrievedAt=capture['retrievedAt'],
                captureKind=capture['captureKind'],notices=result,
                sourceConflicts=[CONFLICT] if kind=='fast-play' else [])


def validate_continuity(candidate,retained,kind):
    new=parse_capture(candidate,kind);old=parse_capture(retained,kind)
    if datetime.fromisoformat(new['retrievedAt'].replace('Z','+00:00')) < datetime.fromisoformat(old['retrievedAt'].replace('Z','+00:00')):
        raise ValueError('ending acquisition regressed')
    if new['notices'] != old['notices']:
        raise ValueError('ending identity/date/order changed; review required')
    return copy.deepcopy(new)
