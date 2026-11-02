"""Strict multi-day Quick Draw assembly and refresh gate; no acquisition or writes."""
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from tooling.arizona_one_to_win import parse_capture as one
from tooling.arizona_two_to_win import parse_capture as positional
from tooling.arizona_pick_your_bet import parse_capture as bet
from tooling.arizona_51045 import parse_capture as five
from tooling.arizona_lucky_links import parse_capture as lucky
from tooling.arizona_hi_lo import parse_capture as hilo

PARSERS = {'one-to-win': one, 'two-to-win': positional,
           '5-in-a-line': lambda c: positional(c, '5-in-a-line'),
           'money-roll': lambda c: positional(c, 'money-roll'),
           'pick-your-bet': bet, '51045': five, 'lucky-links': lucky, 'hi-lo': hilo}


def instant(row):
    return datetime.strptime(row['drawDate'] + ' ' + row['drawTime'],
                             '%Y-%m-%d %I:%M %p').replace(tzinfo=ZoneInfo('America/Phoenix'))


def parse_captures(captures):
    if set(captures) != set(PARSERS):
        raise ValueError('exactly eight Quick Draw sources required')
    groups, provenance = {}, {}
    for game, parser in PARSERS.items():
        days = captures[game]
        if not isinstance(days, list) or not days:
            raise ValueError('dated captures required')
        by_time, by_id, dates = {}, {}, set()
        provenance[game] = []
        for capture in days:
            day = capture['selectedDate']
            if day in dates:
                raise ValueError('duplicate capture day')
            dates.add(day)
            for row in parser(capture):
                key = instant(row)
                if key in by_time or row['drawId'] in by_id:
                    raise ValueError('duplicate draw time or identity')
                by_time[key] = row
                by_id[row['drawId']] = row
            provenance[game].append({k: capture[k] for k in
                                    ('sourceUrl', 'retrievedAt', 'captureKind', 'selectedDate')})
        rows = sorted(by_time.values(), key=instant, reverse=True)
        for newer, older in zip(rows, rows[1:]):
            previous = instant(older)
            expected = (previous + timedelta(hours=1) if previous.hour < 23 else
                        (previous + timedelta(days=1)).replace(hour=5 if game == 'lucky-links' else 4))
            if instant(newer) != expected or int(newer['drawId']) != int(older['drawId']) + 1:
                raise ValueError('missing scheduled draw or discontinuous identity')
        groups[game] = rows
    return groups, provenance


def select_refresh(candidate, retained):
    new, provenance = parse_captures(candidate)
    old, prior_provenance = parse_captures(retained)
    selected = {}
    for game, rows in new.items():
        times = lambda ps: [datetime.fromisoformat(p['retrievedAt'].replace('Z', '+00:00')) for p in ps]
        if max(times(provenance[game])) < max(times(prior_provenance[game])):
            raise ValueError('source retrieval regressed')
        old_days = {p['selectedDate']: p for p in prior_provenance[game]}
        for p in provenance[game]:
            if p['selectedDate'] in old_days and times([p])[0] < times([old_days[p['selectedDate']]])[0]:
                raise ValueError('retained day retrieval regressed')
        by_time = {instant(r): r for r in rows}
        if instant(rows[0]) < instant(old[game][0]):
            raise ValueError('latest draw regressed')
        if any(instant(r) not in by_time for r in old[game][:2]):
            raise ValueError('retained selections missing')
        for row in old[game]:
            if instant(row) >= instant(rows[-1]) and by_time.get(instant(row)) != row:
                raise ValueError('overlapping result missing or corrected')
        selected[game] = rows[:2]
    return {'groups': selected, 'provenance': provenance}
