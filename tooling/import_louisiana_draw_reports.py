"""Fetch all Louisiana draw pages before atomically replacing a validated window."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import tempfile
from louisiana_draw_reports import CENTRAL, REPORT_GAMES, parse_draw_collection


def fetch(url):
    return subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location',
                           '--proto', '=https', '--proto-redir', '=https',
                           '--connect-timeout', '15', '--max-time', '60', url],
                          check=True, capture_output=True).stdout


def validate_window(collection, previous=None):
    reports = collection['reports']
    if collection.get('state') != 'LA' or collection.get('schemaVersion') != 1:
        raise ValueError('Wrong Louisiana collection identity')
    if len(reports) != 14 or Counter(r['game'] for r in reports) != Counter({g: 2 for g in REPORT_GAMES}):
        raise ValueError('Incomplete Louisiana report window')
    if len({(r['game'], r['drawDate']) for r in reports}) != 14:
        raise ValueError('Duplicate Louisiana report identity')
    if previous is not None:
        validate_window(previous)
        for game in REPORT_GAMES:
            before = sorted(r['drawDate'] for r in previous['reports'] if r['game'] == game)
            after = sorted(r['drawDate'] for r in reports if r['game'] == game)
            if any(a < b for a, b in zip(after, before)):
                raise ValueError('Louisiana report window regression')
        old = {(r['game'], r['drawDate']): r for r in previous['reports']}
        for report in reports:
            prior = old.get((report['game'], report['drawDate']))
            if prior and datetime.fromisoformat(report['sourceUpdatedAt']) < datetime.fromisoformat(prior['sourceUpdatedAt']):
                raise ValueError('Louisiana source timestamp regression')


def refresh(output, fetcher=fetch, now=None):
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        raise ValueError('Retrieval timestamp must be timezone-aware')
    output = Path(output)
    previous = json.loads(output.read_text()) if output.exists() else None
    pages = {game: fetcher(f'https://louisianalottery.com/draw-games/{slug}/')
             for game, slug in REPORT_GAMES.items()}
    result = parse_draw_collection(pages, today=now.astimezone(CENTRAL).date())
    validate_window(result, previous)
    if previous and all(previous.get(k) == v for k, v in result.items()):
        return previous
    if previous and now < datetime.fromisoformat(previous['updatedAt']):
        raise ValueError('Louisiana retrieval timestamp regression')
    result['updatedAt'] = now.isoformat()
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=output.parent,
                                         prefix=output.name+'.', suffix='.tmp', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
        temporary.replace(output)
    finally:
        if temporary is not None and temporary.exists(): temporary.unlink()
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    print('Validated Louisiana reports:', len(refresh(args.output)['reports']))
