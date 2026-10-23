"""Collect all supported Idaho components in memory before publication."""
import hashlib
import json
from datetime import datetime
from zoneinfo import ZoneInfo
from tooling.idaho_draw_results import GAMES
from tooling.idaho_result_window import build_window
from tooling.idaho_draw_schedules import parse_schedule
from tooling.idaho_draw_rules import parse_rules
from tooling.idaho_sum_schedules import SPECS as SUM_SPECS, parse_schedule as parse_sum
from tooling.idaho_instant_catalogs import build_catalog
from tooling.idaho_scratch_coverage import build_scratch
from tooling.idaho_raffle import SOURCE as RAFFLE, parse_raffle
from tooling.import_idaho_scratch_catalog import ROOT, SOURCE as SCRATCH, CLAIMS


def collect(fetch, *, now=None):
    now = now or datetime.now(ZoneInfo('UTC'))
    if now.tzinfo is None: raise ValueError('Collection timestamp needs timezone')
    as_of = now.astimezone(ZoneInfo('America/Boise')).date()
    evidence = []
    def get(url):
        raw = fetch(url)
        if not isinstance(raw, bytes) or not raw: raise ValueError('Empty/nonbyte source')
        evidence.append({'url':url, 'sha256':hashlib.sha256(raw).hexdigest()})
        return raw
    pages, schedules, rules = {}, {}, {}
    for slug in list(GAMES) + ['millionaire-for-life']:
        raw = get(ROOT+'/games/draw/'+slug)
        schedules[slug] = parse_schedule(raw,slug)
        rules[slug] = parse_rules(raw,slug)
        pages[slug] = raw
    window = build_window(pages, lambda url:json.loads(get(url)), as_of=as_of)
    sums = {s:parse_sum(s,get(spec['sourceUrl'])) for s,spec in SUM_SPECS.items()}
    instants = {kind:build_catalog(get(ROOT+'/games/'+kind),kind,get)
                for kind in ['instaplay','tabs']}
    scratch = build_scratch(get(SCRATCH),get(CLAIMS),get,as_of=as_of)
    raffle = parse_raffle(get(RAFFLE),as_of=as_of)
    return {'schemaVersion':1,'state':'Idaho','collectionStartedAt':now.isoformat(),
            'results':window['results'],'schedules':schedules,'rules':rules,
            'sumSchedules':sums,'instantCatalogs':instants,'scratch':scratch,
            'raffle':raffle,'sourceEvidence':evidence,
            'coverage':'Bounded supported results, exact-date Idaho reports or explicit gaps, literal schedules/rules and separate typed products. No complete history, claims, stock or retailer joins.'}
