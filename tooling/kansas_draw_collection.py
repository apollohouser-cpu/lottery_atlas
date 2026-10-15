"""Assemble bounded Kansas results and separately identified literal schedules."""
from datetime import datetime, timezone

from tooling.kansas_advertised_prizes import parse_advertised_prizes
from tooling.kansas_draw_results import GROUPS, parse_results
from tooling.kansas_draw_schedules import SCHEMAS, parse_schedule


def assemble_collection(result_pages, schedule_cms, team_mapping, advertised_games, retrieved_at):
    """Accept raw inputs only; every group and schedule must validate together.

    Schedules are keyed by source slug to avoid duplicating Pick 3 and Powerball
    rules across their result groups. No raw prize-tier counts or payouts enter
    this collection. This function performs no network or filesystem writes.
    """
    if not isinstance(result_pages, dict) or set(result_pages) != set(GROUPS):
        raise ValueError('Expected exactly twelve current result groups')
    if not isinstance(schedule_cms, dict) or set(schedule_cms) != set(SCHEMAS):
        raise ValueError('Expected exactly ten current schedule families')
    if not isinstance(retrieved_at, str):
        raise ValueError('Missing retrieval timestamp')
    retrieval = datetime.fromisoformat(retrieved_at.replace('Z', '+00:00'))
    if retrieval.tzinfo is None:
        raise ValueError('Retrieval timestamp must have timezone')
    retrieved_at = retrieval.astimezone(timezone.utc).isoformat()
    schedules = {slug: parse_schedule(schedule_cms[slug], slug) for slug in sorted(SCHEMAS)}
    reports = []
    for group in sorted(GROUPS):
        parsed = parse_results(result_pages[group], group, retrieved_at, team_mapping)
        slug = GROUPS[group][3]
        if len(parsed) != 2 or slug not in schedules:
            raise ValueError('Incomplete result/schedule association')
        for report in parsed:
            report['scheduleKey'] = slug
            reports.append(report)
    if len(reports) != 24 or len({report['id'] for report in reports}) != 24:
        raise ValueError('Incomplete or duplicate bounded results')
    return {
        'schemaVersion': 1,
        'state': 'KS',
        'retrievedAt': retrieved_at,
        'reports': reports,
        'advertisedPrizes': parse_advertised_prizes(advertised_games, retrieved_at),
        'schedules': schedules,
        'coverage': {
            'resultUnit': 'Published drawn numbers, not Kansas winner counts or actual payouts.',
            'window': 'Two recent results per current group; twelve groups across ten families.',
            'frequentGames': 'Keno and Racetrax are bounded snapshots, not a live results service.',
            'dates': 'Local draw date derived in America/Chicago; raw UTC timestamp and source date retained.',
            'prizes': 'Literal schedules are separate from results. Advertised amounts are separately dated source values, not calculated awards.',
            'excluded': ['Unverified prize-tier share counts and payout amounts',
                         'Historical Lucky for Life and raffle results',
                         'Full historical archives', 'Retailer joins or map coordinates'],
        },
    }
