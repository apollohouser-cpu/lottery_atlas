"""Assemble validated Nebraska captures without publishing partial collections.

Literal rules remain separate from dated prize reports.
This module deliberately keeps dated reports separate from bounded number rows.
"""
from tooling.nebraska_draw_results import SPECS, parse_results
from tooling.nebraska_draw_reports import parse_regular_report
from tooling.nebraska_powerball_report import parse_powerball
from tooling.nebraska_mega_millions_report import parse_mega_millions
from tooling.nebraska_lotto_america_report import parse_lotto_america
from tooling.nebraska_2by2_report import parse_2by2
from tooling.nebraska_regular_schedules import parse_regular_schedule

OPTION_PARSERS = {
    'Powerball': parse_powerball,
    'Mega Millions': parse_mega_millions,
    'Lotto America': parse_lotto_america,
    '2by2': parse_2by2,
}


def assemble_collection(pages, *, today, previous=None):
    """Return all ten families or raise; never mutate inputs or write outputs.

    Optional prior collection prevents a successful refresh from regressing any
    group's newest result or losing any previously retained report variant.
    """
    if set(pages) != set(SPECS):
        raise ValueError('Missing or unexpected Nebraska family')
    results, reports = [], []
    for family in SPECS:
        try:
            results.extend(parse_results(pages[family], family, today=today))
            parser = OPTION_PARSERS.get(family)
            reports.append(parser(pages[family], today=today) if parser else
                           parse_regular_report(pages[family], family, today=today))
            reports[-1]['ruleBlocks'] = parse_regular_schedule(pages[family], family)
        except ValueError as error:
            raise ValueError(f'{family}: {error}') from error
    collection = dict(state='NE', results=results, familyReports=reports,
                      limitation='Bounded number results and separately dated latest reports. Older number rows do not inherit winner counts. Source Winners are not unique people or complete claims. No retailer joins or coordinates.')
    if previous is not None:
        old_results = _newest_results(previous)
        new_results = _newest_results(collection)
        old_reports = _report_dates(previous)
        new_reports = _report_dates(collection)
        for old, new in ((old_results, new_results), (old_reports, new_reports)):
            if old.keys() != new.keys() or any(new[key] < stamp for key, stamp in old.items()):
                raise ValueError('Missing group/variant or regressed Nebraska date')
    return collection


def _newest_results(collection):
    dates = {}
    for result in collection['results']:
        key = (result['family'], result['group'])
        dates[key] = max(dates.get(key, ''), result['drawDate'])
    return dates


def _report_dates(collection):
    dates = {}
    for family in collection['familyReports']:
        for report in family.get('reports', [family]):
            key = (family['family'], report.get('variant', 'regular'))
            if key in dates:
                raise ValueError('Duplicate report variant')
            dates[key] = report['drawDate']
    return dates
