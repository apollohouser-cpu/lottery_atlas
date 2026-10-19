"""Private atomic Iowa draw/report/rule collection; publication is a separate gate."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
from zoneinfo import ZoneInfo

from tooling.iowa_draw_results import SPECS as RESULTS, parse_results
from tooling.iowa_draw_reports import SPECS as REPORTS, parse_reports, attach_report
from tooling.iowa_team_results import parse_team_results
from tooling.iowa_schedules import SPECS as CHARTS, verified_chart
from tooling.iowa_html_schedules import PAGES, verified_html_schedule

BASE = 'https://www.ialottery.com/Pages/Games-Online/'
REPORT_PAGES = dict(powerball='PowerballPrizes', double_play='PowerballPrizes',
                    mega_millions='MegaMillionsPrizes', lotto_america='LottoAmericaPrizes',
                    millionaire_for_life='MillionaireForLifePrizes', xsos='PowerballXOPrizes')
STAGE = 'private-iowa-results-reports-rules-v1'
GROUPS = set(RESULTS) | {'xsos'}


def fetch_page(url):
    # The ordinary public site accepts curl; no credentials or private APIs.
    result = subprocess.run(['curl', '-fsSL', '--max-time', '45', '--max-filesize',
                             '5000000', url], capture_output=True, check=True)
    if not result.stdout or len(result.stdout) > 5_000_000:
        raise ValueError('Empty or oversized Iowa source')
    return result.stdout


def check_continuity(previous, current):
    if previous is None:
        return
    if previous.get('stage') != STAGE or previous.get('state') != 'Iowa':
        raise ValueError('Unrecognized retained Iowa collection')
    old_time = datetime.fromisoformat(previous['retrievedAt'])
    if old_time.utcoffset() is None or old_time > datetime.fromisoformat(current['retrievedAt']):
        raise ValueError('Retrieval time regression')
    for field in ('charts', 'rules'):
        if previous.get(field) != current[field]:
            raise ValueError('Retained rule correction requires review')
    for records in (previous['results'], current['results']):
        if len(records) != 20 or {r['group'] for r in records} != GROUPS:
            raise ValueError('Incomplete retained result groups')
        if len({(r['group'], r['drawDate']) for r in records}) != 20:
            raise ValueError('Duplicate retained result identity')
    for group in GROUPS:
        old = [r for r in previous['results'] if r['group'] == group]
        new = [r for r in current['results'] if r['group'] == group]
        if len(old) != 2 or len(new) != 2 or max(r['drawDate'] for r in new) < max(r['drawDate'] for r in old):
            raise ValueError('Result date regression')
        indexed = {r['drawDate']: r for r in old}
        for row in new:
            if row['drawDate'] in indexed and row != indexed[row['drawDate']]:
                raise ValueError('Dated result/report change requires review')


def collect(output, *, fetch=fetch_page, now=None):
    now = now or datetime.now(timezone.utc)
    if now.utcoffset() is None:
        raise ValueError('Aware retrieval time required')
    as_of = now.astimezone(ZoneInfo('America/Chicago')).date()
    output = Path(output)
    previous = json.loads(output.read_text()) if output.exists() else None
    cache = {}

    def source(url):
        if url not in cache:
            raw = fetch(url)
            if not isinstance(raw, bytes) or not raw or len(raw) > 5_000_000:
                raise ValueError('Invalid source bytes')
            cache[url] = raw
        return cache[url]

    results = []
    for group, spec in RESULTS.items():
        results.extend(parse_results(source(BASE + spec[0] + '.aspx'), group, as_of=as_of))
    results.extend(parse_team_results(source(BASE + 'PowerballXOWin.aspx'), as_of=as_of))
    reports = {group: parse_reports(source(BASE + REPORT_PAGES[group] + '.aspx'), group, as_of=as_of)
               for group in REPORTS}
    results = [attach_report(row, reports[row['group']]) if row['group'] in reports else
               {**row, 'report': None, 'reportLimitation': 'Pick source count units/geography unverified; counts excluded, not zero'}
               for row in results]
    charts = [verified_chart(s['game'], source(s['sourceUrl'])) for s in CHARTS]
    rules = [verified_html_schedule(game, source(BASE + page + '.aspx')) for game, page in PAGES.items()]
    if len(results) != 20 or {r['group'] for r in results} != GROUPS or len(charts) != 8 or len(rules) != 9:
        raise ValueError('Incomplete Iowa collection')
    result = dict(stage=STAGE, state='Iowa', retrievedAt=now.isoformat(), results=results,
                  charts=charts, rules=rules,
                  sources=[{'url': url, 'sha256': hashlib.sha256(raw).hexdigest()} for url, raw in cache.items()],
                  limitations=['Bounded two results per group; not complete history.',
                               'Pick counts excluded; no zero substitution.',
                               'XsOs labels are literal source abbreviations, not expanded team names.',
                               'Shared Powerball rules include separate base and Double Play sections.'])
    check_continuity(previous, result)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=output.parent,
                                         prefix='.' + output.name + '.', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return result


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = collect(args.output)
    print(f"Validated {len(result['results'])} results, {len(result['charts'])} charts, {len(result['rules'])} rule pages")
