"""All-or-error product refresh selection; never writes or invents inventory."""
import re
from datetime import datetime
from arizona_scratch_details import validate_continuity as scratch_refresh
from arizona_fast_play_details import validate_continuity as fast_refresh


def _index(rows, kind):
    if not isinstance(rows,list) or not rows:
        raise ValueError('product captures required')
    result={}
    for row in rows:
        if not isinstance(row,dict):
            raise ValueError('invalid product capture')
        match=re.fullmatch(r'https://www\.arizonalottery\.com/'+kind+r'/([0-9]+)-[a-z0-9-]+/',row.get('sourceUrl',''))
        if not match or match[1] in result:
            raise ValueError('duplicate or invalid product source')
        number=match[1]
        header=row.get('header','').splitlines()
        if len(header)!=3 or not header[0].endswith(' #'+number):
            raise ValueError('product header/source identity mismatch')
        info=re.fullmatch(r'Ticket Price: \$([0-9]+) (Start Date: ([0-9]+/[0-9]+/[0-9]{4})|Game Ended)',header[2])
        if not info or int(info[1])<=0:
            raise ValueError('invalid price/date/status')
        if info[3]:datetime.strptime(info[3],'%m/%d/%Y')
        result[number]=row
    return result


def select_refresh(candidate,retained):
    """Retained set is the explicitly reviewed matrix, including ended products.

    A new/removed product or status transition requires review before adoption.
    No output is returned until both catalogs pass every continuity check.
    """
    for bundle in (candidate,retained):
        if not isinstance(bundle,dict) or set(bundle)!={'scratchers','fast-play'}:
            raise ValueError('both product catalogs required')
    output={}
    for kind,validator in [('scratchers',scratch_refresh),('fast-play',fast_refresh)]:
        current=_index(candidate[kind],kind);old=_index(retained[kind],kind)
        if set(current)!=set(old):
            raise ValueError('product identity set changed; review required')
        products=[]
        for number in sorted(old,key=int):
            capture=current[number]
            parsed=validator(capture,old[number])
            parsed.update(gameNumber=number,header=capture['header'],
                          sourceStatus='ended' if capture['header'].endswith('Game Ended') else 'start-date-listed')
            products.append(parsed)
        output[kind]=products
    return output
