"""Refresh each state as a transaction; never publish a half-refreshed state."""
import html
import json
import os
from pathlib import Path
import subprocess
from datetime import datetime, timezone


def refresh(jobs, root, run=subprocess.run):
    results = []
    fatal = False
    for job in jobs:
        paths = [root / name for name in job['outputs']]
        before = {p: p.read_bytes() if p.exists() else None for p in paths}
        # A fallback must be an existing, parseable, tracked baseline. Global
        # publication validators still check its schema and source constraints.
        baseline = all(value is not None for value in before.values())
        if baseline:
            for value in before.values():
                json.loads(value)
        failure = None
        for command in job['commands']:
            print(f"Refreshing {job['state']}: {command[1]}", flush=True)
            try:
                result = run(command, cwd=root, timeout=1200, check=False)
                if result.returncode:
                    failure = 'Importer failed validation or could not retrieve its source.'
                    break
            except subprocess.TimeoutExpired:
                failure = 'Importer exceeded the refresh time limit.'
                break
            except OSError:
                failure = 'Importer could not be started.'
                break
        if failure is None:
            try:
                for p in paths:
                    json.loads(p.read_bytes())
            except (OSError, ValueError):
                failure = 'Importer did not produce valid JSON output.'
        if failure:
            for p, value in before.items():
                if value is None:
                    p.unlink(missing_ok=True)
                else:
                    p.write_bytes(value)
            fatal |= not baseline
            print(f"::warning::{job['state']}: {failure} Previous files and dates retained.")
        unchanged = failure is None and all(p.read_bytes() == before[p] for p in paths)
        results.append({
            'state': job['state'],
            'status': 'retained_after_failure' if failure else ('unchanged' if unchanged else 'updated'),
            'message': failure or ('No file changes; this does not establish a new source date.' if unchanged else 'Import completed; source dates remain in each dataset.'),
            'files': job['outputs'],
        })
    return results, fatal


def write_report(results, root):
    checked = datetime.now(timezone.utc).isoformat()
    report = {'attemptedAt': checked, 'note': 'Refresh attempts are not source dates or proof of complete statewide coverage.', 'states': results}
    (root / 'docs/state_refresh_status.json').write_text(json.dumps(report, indent=2) + '\n')
    rows = ''.join('<tr>' + ''.join(f'<td>{html.escape(row[key])}</td>' for key in ['state', 'status', 'message']) + '</tr>' for row in results)
    (root / 'docs/state_refresh_status.html').write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width">'
        '<title>Lottery Atlas refresh status</title><style>body{font:16px system-ui;max-width:70rem;margin:2rem auto;padding:1rem}td,th{text-align:left;padding:.7rem;border-bottom:1px solid #ccc}</style>'
        '<h1>State refresh status</h1><p>Last refresh attempt: ' + html.escape(checked) + '</p>'
        '<p>A failed state keeps its previous data and original dates. Other states can update independently. '
        'An unchanged result can include an importer retaining its prior snapshot; it is not a new source verification date. '
        'Coverage and source dates are listed in the individual datasets. Updates do not establish complete statewide coverage.</p>'
        '<table><thead><tr><th>State</th><th>Refresh result</th><th>Details</th></tr></thead><tbody>' + rows + '</tbody></table></html>\n')
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
            f.write('## State refresh results\n\n' + '\n'.join(f"- {r['state']}: {r['status']}" for r in results) + '\n')


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    jobs = json.loads((root / 'tooling/state_refresh_jobs.json').read_text())
    results, fatal = refresh(jobs, root)
    write_report(results, root)
    if fatal:
        raise SystemExit('A failed state has no usable baseline; publication stopped.')
