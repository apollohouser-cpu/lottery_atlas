"""Continuity checks for already strictly parsed Arizona result collections."""


def select_latest(candidate, retained):
    """Validate same groups and overlapping dates before selecting two each.

    Inputs must be full outputs from strict source parsers, ordered newest first.
    No persistence or source acquisition is performed here.
    """
    if not candidate or set(candidate) != set(retained):
        raise ValueError('draw groups changed')
    selected = {}
    for game, rows in candidate.items():
        old = retained[game]
        for collection in (rows, old):
            dates = [r['drawDate'] for r in collection]
            if len(dates) < 2 or dates != sorted(set(dates), reverse=True):
                raise ValueError('two or more distinct ordered results required')
            if any(r['game'] != game for r in collection):
                raise ValueError('draw group identity mismatch')
        by_date = {r['drawDate']: r for r in rows}
        if rows[0]['drawDate'] < old[0]['drawDate']:
            raise ValueError('latest draw regressed')
        if any(r['drawDate'] not in by_date for r in old[:2]):
            raise ValueError('retained selections missing')
        for row in old:
            if row['drawDate'] >= rows[-1]['drawDate'] and by_date.get(row['drawDate']) != row:
                raise ValueError('overlapping result missing or corrected')
        selected[game] = rows[:2]
    return selected
