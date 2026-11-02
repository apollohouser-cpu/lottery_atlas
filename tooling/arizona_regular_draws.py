"""Validate all eight regular-draw captures together; not a public feed.

QuickDraw, rules and products remain separate prerequisites. Each source keeps
its actual retrieval time; a shared collection time is never manufactured.
"""
from datetime import datetime

from tooling.arizona_daily_lotto import parse_capture as single_pool
from tooling.arizona_draw_continuity import select_latest
from tooling.arizona_megamillions import parse_capture as mega
from tooling.arizona_pick3 import parse_capture as digits
from tooling.arizona_powerball import parse_capture as powerball
from tooling.arizona_xsos import parse_capture as xsos

SOURCES = frozenset(('powerball', 'powerball-xs-os', 'mega-millions',
                     'the-pick', 'fantasy-5', 'triple-twist', 'pick-3', 'pick-4'))


def parse_captures(captures):
    if set(captures) != SOURCES:
        raise ValueError('exactly eight regular draw sources required')
    groups = {}
    provenance = {}
    for source in sorted(SOURCES):
        capture = captures[source]
        if source == 'powerball':
            parsed = powerball(capture)
        elif source in ('pick-3', 'pick-4'):
            parsed = digits(capture, source)
        else:
            rows = (mega(capture) if source == 'mega-millions' else
                    xsos(capture) if source == 'powerball-xs-os' else
                    single_pool(capture, source))
            parsed = {source: rows}
        if set(groups) & set(parsed):
            raise ValueError('duplicate result group')
        groups.update(parsed)
        for group in parsed:
            provenance[group] = dict(sourceUrl=capture['sourceUrl'],
                                     retrievedAt=capture['retrievedAt'],
                                     captureKind=capture['captureKind'])
    return groups, provenance


def select_refresh(candidate, retained):
    """Reject any source regression/correction before returning all 22 results."""
    new, provenance = parse_captures(candidate)
    old, _ = parse_captures(retained)
    for source in SOURCES:
        time = lambda bundle: datetime.fromisoformat(
            bundle[source]['retrievedAt'].replace('Z', '+00:00'))
        if time(candidate) < time(retained):
            raise ValueError('source retrieval regressed')
    return dict(groups=select_latest(new, old), provenance=provenance)
