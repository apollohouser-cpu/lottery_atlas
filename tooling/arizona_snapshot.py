"""Private validated staging snapshot, not a production feed or acceptance marker."""
import json
import os
import tempfile
from datetime import datetime
from pathlib import Path
from tooling.arizona_draw_bundle import select_refresh as draw_refresh
from arizona_product_bundle import select_refresh as product_refresh
from arizona_rules import CONTRACTS as RULES, parse_capture as parse_rule
from arizona_rule_details import CONTRACTS as DETAILS, parse_capture as parse_detail


def validate(candidate,retained):
    required={'draws','products','rules','details'}
    for bundle in (candidate,retained):
        if not isinstance(bundle,dict) or set(bundle)!=required:
            raise ValueError('complete Arizona source snapshot required')
    result={'draws':draw_refresh(candidate['draws'],retained['draws']),
            'products':product_refresh(candidate['products'],retained['products'])}
    for family,contracts,parser in [('rules',RULES,parse_rule),('details',DETAILS,parse_detail)]:
        for bundle in (candidate,retained):
            if set(bundle[family])!=set(contracts):
                raise ValueError('complete reviewed rule source set required')
        result[family]={}
        for game in contracts:
            old=parser(retained[family][game],game)
            new=parser(candidate[family][game],game)
            if datetime.fromisoformat(new['retrievedAt'].replace('Z','+00:00'))<datetime.fromisoformat(old['retrievedAt'].replace('Z','+00:00')):
                raise ValueError('rule acquisition regressed')
            result[family][game]=new
    return result


def stage(candidate,retained,destination):
    """Validate everything before touching destination; replace a single file."""
    validated=validate(candidate,retained)
    payload={'schemaVersion':1,'status':'private-development-snapshot',
             'productionReady':False,'captures':candidate,'validated':validated}
    data=(json.dumps(payload,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()
    destination=Path(destination)
    temporary=None
    try:
        with tempfile.NamedTemporaryFile(dir=destination.parent,prefix='.'+destination.name+'.',delete=False) as stream:
            temporary=Path(stream.name)
            stream.write(data);stream.flush();os.fsync(stream.fileno())
        os.replace(temporary,destination)
        temporary=None
    finally:
        if temporary is not None:temporary.unlink(missing_ok=True)
    return validated
